#!/usr/bin/env bash
# Shared helpers for every gkvm script. Sourced, never executed.
#
# Conventions:
#   - scripts run with the module repository root as the working directory
#   - GKVM_HOME points at the gkvm-tools checkout (set by the Makefile)
#   - GKVM_BINARY selects the CLI: tofu (default) or terraform
#   - GKVM_PROFILE forces a profile: base | azure | github (default: auto)
#   - a flat .gkvm.yml in the repo root may set `profile:` and `binary:`

set -euo pipefail

GKVM_HOME="${GKVM_HOME:?GKVM_HOME must point at the gkvm-tools checkout}"
GKVM_ROOT="$(pwd)"
GKVM_CONFIG="${GKVM_ROOT}/.gkvm.yml"

# --- logging ---------------------------------------------------------------

gkvm_info()  { printf '==> %s\n' "$*"; }
gkvm_step()  { printf '===> %s\n' "$*"; }
gkvm_warn()  { printf '==> WARNING: %s\n' "$*" >&2; }
gkvm_fail()  { printf '==> ERROR: %s\n' "$*" >&2; exit 1; }

# --- configuration ---------------------------------------------------------

# Read a flat `key: value` line from .gkvm.yml. Nested YAML is not supported
# on purpose: the file stays greppable and needs no parser in the image.
gkvm_config() {
  local key="$1"
  [ -f "$GKVM_CONFIG" ] || return 0
  sed -nE "s/^${key}:[[:space:]]*\"?([^\"#]*)\"?[[:space:]]*(#.*)?$/\1/p" "$GKVM_CONFIG" | head -n1 | xargs
}

gkvm_binary() {
  local bin="${GKVM_BINARY:-$(gkvm_config binary)}"
  bin="${bin:-tofu}"
  case "$bin" in
    tofu|terraform) ;;
    *) gkvm_fail "unsupported binary '$bin' (want tofu or terraform)" ;;
  esac
  command -v "$bin" >/dev/null || gkvm_fail "$bin is not installed"
  printf '%s' "$bin"
}

# Detect the profile from the root module's required_providers. Explicit
# settings win: GKVM_PROFILE, then .gkvm.yml, then detection.
gkvm_profile() {
  local profile="${GKVM_PROFILE:-$(gkvm_config profile)}"
  profile="${profile:-auto}"
  if [ "$profile" = "auto" ]; then
    local sources
    sources="$(cat "$GKVM_ROOT"/*.tf 2>/dev/null | grep -iE '^\s*source\s*=' | tr '[:upper:]' '[:lower:]' || true)"
    if grep -qE '"(hashicorp/azurerm|azure/azapi|hashicorp/azuread)"' <<<"$sources"; then
      profile=azure
    elif grep -qE '"integrations/github"' <<<"$sources"; then
      profile=github
    else
      profile=base
    fi
  fi
  [ -d "$GKVM_HOME/profiles/$profile" ] || gkvm_fail "unknown profile '$profile'"
  printf '%s' "$profile"
}

# --- scope discovery -------------------------------------------------------

# Print "<kind> <dir>" for the root module, every modules/* and every
# examples/* directory that contains at least one .tf file.
gkvm_scopes() {
  printf 'root .\n'
  local d
  for d in modules/*/ examples/*/; do
    [ -d "$d" ] || continue
    d="${d%/}"
    ls "$d"/*.tf >/dev/null 2>&1 || continue
    case "$d" in
      modules/*)  printf 'module %s\n' "$d" ;;
      examples/*) printf 'example %s\n' "$d" ;;
    esac
  done
}

gkvm_examples() { gkvm_scopes | awk '$1 == "example" { print $2 }'; }

# --- terraform-docs config resolution -------------------------------------
# Order: <scope>/.terraform-docs.yml, <parent>/.terraform-docs.yml (for
# examples/ and modules/), the repository root, then the profile default.
gkvm_docs_config() {
  local dir="$1" candidate
  for candidate in \
    "$GKVM_ROOT/$dir/.terraform-docs.yml" \
    "$GKVM_ROOT/$(dirname "$dir")/.terraform-docs.yml" \
    "$GKVM_ROOT/.terraform-docs.yml" \
    "$GKVM_HOME/profiles/$(gkvm_profile)/terraform-docs.yml"; do
    if [ -f "$candidate" ]; then printf '%s' "$candidate"; return; fi
  done
  gkvm_fail "no terraform-docs config found for $dir"
}

# --- tflint config resolution ----------------------------------------------
# Profile config merged with an optional repository override. Both the new
# .gkvm/tflint.<kind>.override.hcl and the legacy AVM file names are honoured
# so migrated repositories keep working without edits.
gkvm_tflint_config() {
  local kind="$1" profile base override merged
  profile="$(gkvm_profile)"
  base="$GKVM_HOME/profiles/$profile/tflint.$kind.hcl"
  [ -f "$base" ] || gkvm_fail "profile $profile has no tflint.$kind.hcl"
  local legacy
  case "$kind" in
    root)    legacy="avm.tflint.override.hcl" ;;
    module)  legacy="avm.tflint_module.override.hcl" ;;
    example) legacy="avm.tflint_example.override.hcl" ;;
  esac
  for override in "$GKVM_ROOT/.gkvm/tflint.$kind.override.hcl" "$GKVM_ROOT/$legacy"; do
    if [ -f "$override" ]; then
      merged="$(mktemp -t gkvm-tflint-XXXXXX).hcl"
      hclmerge -1 "$override" -2 "$base" -d "$merged" >/dev/null
      printf '%s' "$merged"
      return
    fi
  done
  printf '%s' "$base"
}

# Plugins are pre-installed in the image under TFLINT_PLUGIN_DIR; elsewhere
# `tflint --init` downloads them on first use.
gkvm_tflint_init() {
  local config="$1"
  tflint --init --config="$config" >/dev/null
}

# --- provider cache --------------------------------------------------------
# One plugin cache per run keeps init fast across scopes without touching the
# user's own cache directory.
gkvm_plugin_cache() {
  if [ -z "${TF_PLUGIN_CACHE_DIR:-}" ]; then
    export TF_PLUGIN_CACHE_DIR="${GKVM_CACHE_DIR:-${TMPDIR:-/tmp}/gkvm-plugin-cache}"
  fi
  mkdir -p "$TF_PLUGIN_CACHE_DIR"
}

# Example directories may opt out of plan/apply with an .e2eignore marker.
gkvm_example_ignored() { [ -f "$1/.e2eignore" ]; }

gkvm_run_hook() {
  local dir="$1" hook="$2"
  if [ -f "$dir/$hook" ]; then
    gkvm_step "running $hook in $dir"
    (cd "$dir" && bash "./$hook")
  fi
}
