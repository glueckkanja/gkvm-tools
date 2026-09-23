#!/usr/bin/env bash
# Fail when any README.md is out of date. Uses terraform-docs' own
# --output-check, so nothing in the working tree is modified.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
failed=false
while read -r kind dir; do
  config="$(gkvm_docs_config "$dir")"
  gkvm_step "checking docs for $kind $dir"
  if ! terraform-docs -c "$config" --output-check "$dir" >/dev/null; then
    echo "     $dir/README.md is out of date"
    failed=true
  fi
done < <(gkvm_scopes)
$failed && gkvm_fail "documentation drift; run 'gkvm docs' (or 'gkvm pre-commit') and commit"
gkvm_info "docs up to date"
