#!/usr/bin/env bash
# Apply AVM block ordering (avmfix) to every scope and format HCL blocks
# embedded in markdown (terrafmt). README.md files are generated and skipped.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
while read -r kind dir; do
  gkvm_step "avmfix $kind $dir"
  avmfix -folder "$dir"
done < <(gkvm_scopes)
gkvm_step "terrafmt markdown"
while IFS= read -r -d '' f; do
  terrafmt fmt -f "$f" >/dev/null
done < <(find . -type f -name '*.md' \
          -not -name README.md \
          -not -path './.git/*' -not -path './.github/*' \
          -not -path '*/.terraform/*' -print0)
gkvm_info "fix applied"
