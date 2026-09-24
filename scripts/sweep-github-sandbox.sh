#!/usr/bin/env bash
# Delete leftovers of end-to-end runs from a GitHub sandbox organisation.
#
# Runs on a GitHub Actions runner, not inside the gkvm-tools image: it needs the
# gh CLI, which the image does not ship. Driven by the reusable workflow
# .github/workflows/sweep-github-sandbox.yml, and usable by hand with GH_TOKEN
# set to a token for the sandbox organisation.
#
# A successful e2e run destroys everything it created. Leftovers come from
# cancelled or crashed runs. Everything here is therefore matched by name prefix
# and, where the API exposes a creation timestamp, gated on age.
#
# Environment:
#   OWNER           the sandbox organisation (required)
#   PREFIX          name prefix to match (required, at least 5 characters)
#   MAX_AGE_HOURS   only delete objects older than this (default 24)
#   DRY_RUN         "true" lists without deleting (default true)

set -euo pipefail

OWNER="${OWNER:?OWNER must name the sandbox organisation}"
PREFIX="${PREFIX:?PREFIX must be set}"
MAX_AGE_HOURS="${MAX_AGE_HOURS:-24}"
DRY_RUN="${DRY_RUN:-true}"

# A short prefix would match real repositories. Refuse rather than guess.
if [ "${#PREFIX}" -lt 5 ]; then
  echo "::error::PREFIX '$PREFIX' is shorter than 5 characters; refusing to sweep" >&2
  exit 1
fi

cutoff=$(( $(date -u +%s) - MAX_AGE_HOURS * 3600 ))
summary="${GITHUB_STEP_SUMMARY:-/dev/null}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

echo "==> sweeping '$OWNER' for '$PREFIX*' older than ${MAX_AGE_HOURS}h (dry_run=$DRY_RUN)"
{
  echo "## Sandbox sweep"
  echo
  echo "| Kind | Name | Age | Action |"
  echo "| --- | --- | --- | --- |"
} >> "$summary"

age_hours() { echo $(( ( $(date -u +%s) - $1 ) / 3600 )); }

record() { # kind name age action
  # shellcheck disable=SC2016  # the backticks are markdown for the job summary
  printf '| %s | `%s` | %sh | %s |\n' "$1" "$2" "$3" "$4" >> "$summary"
  printf '  %-8s %-45s %4sh  %s\n' "$1" "$2" "$3" "$4"
}

# `gh api -X DELETE` on a missing object is a hard error; a concurrent run may
# have removed it already, so a failure is reported and does not abort the sweep.
remove() { # endpoint kind name age
  if [ "$DRY_RUN" = "true" ]; then
    record "$1" "$3" "$4" "would delete"
    return 0
  fi
  if gh api -X DELETE "$2" --silent 2>"$work/err"; then
    record "$1" "$3" "$4" "deleted"
  else
    record "$1" "$3" "$4" "FAILED: $(tr -d '\n' < "$work/err" | cut -c1-120)"
    echo "1" >> "$work/failures"
  fi
}

# --- repositories, timestamped ----------------------------------------------
gh api --paginate "orgs/$OWNER/repos?per_page=100" \
  --jq '.[] | [.name, .created_at] | @tsv' > "$work/repos" || : > "$work/repos"

while IFS=$'\t' read -r name created; do
  [ -n "$name" ] || continue
  case "$name" in "$PREFIX"*) ;; *) continue ;; esac
  ts=$(date -u -d "$created" +%s)
  age=$(age_hours "$ts")
  if [ "$ts" -lt "$cutoff" ]; then
    remove repo "repos/$OWNER/$name" "$name" "$age"
  else
    record repo "$name" "$age" "kept, younger than cutoff"
    echo "1" >> "$work/young"
  fi
done < "$work/repos"

# --- teams, timestamped only through GraphQL --------------------------------
# shellcheck disable=SC2016  # $owner is a GraphQL variable, not a shell one
gh api graphql -f owner="$OWNER" -f query='
  query($owner: String!) {
    organization(login: $owner) {
      teams(first: 100) { nodes { slug createdAt } }
    }
  }' --jq '.data.organization.teams.nodes[] | [.slug, .createdAt] | @tsv' > "$work/teams" || : > "$work/teams"

while IFS=$'\t' read -r slug created; do
  [ -n "$slug" ] || continue
  case "$slug" in "$PREFIX"*) ;; *) continue ;; esac
  ts=$(date -u -d "$created" +%s)
  age=$(age_hours "$ts")
  if [ "$ts" -lt "$cutoff" ]; then
    remove team "orgs/$OWNER/teams/$slug" "$slug" "$age"
  else
    record team "$slug" "$age" "kept, younger than cutoff"
    echo "1" >> "$work/young"
  fi
done < "$work/teams"

# --- organisation rulesets and custom property definitions ------------------
# Neither endpoint returns a creation timestamp in its listing, so these cannot
# be age-gated. They are only skipped entirely while a prefixed repository or
# team is younger than the cutoff, because that means a run may still be in
# flight and its organisation-level objects must survive.
if [ -f "$work/young" ]; then
  echo "==> organisation-level objects skipped: a prefixed repo or team is younger than the cutoff"
  record org-level "-" 0 "skipped, a run may be in flight"
else
  gh api --paginate "orgs/$OWNER/rulesets?per_page=100" \
    --jq '.[] | [(.id|tostring), .name] | @tsv' > "$work/rulesets" || : > "$work/rulesets"
  while IFS=$'\t' read -r id name; do
    [ -n "$id" ] || continue
    case "$name" in "$PREFIX"*) ;; *) continue ;; esac
    remove ruleset "orgs/$OWNER/rulesets/$id" "$name" 0
  done < "$work/rulesets"

  gh api "orgs/$OWNER/properties/schema" \
    --jq '.[] | .property_name' > "$work/properties" || : > "$work/properties"
  while read -r name; do
    [ -n "$name" ] || continue
    # Property names cannot contain hyphens everywhere, so an underscore variant
    # of the prefix counts as a match too.
    case "$name" in
      "$PREFIX"* | "${PREFIX//-/_}"*) ;;
      *) continue ;;
    esac
    remove property "orgs/$OWNER/properties/schema/$name" "$name" 0
  done < "$work/properties"
fi

if [ -f "$work/failures" ]; then
  echo "::error::$(wc -l < "$work/failures" | tr -d ' ') object(s) could not be deleted"
  exit 1
fi

echo "==> sweep complete"
