#!/usr/bin/env bash
# Regenerate README.md for every scope with terraform-docs.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
while read -r kind dir; do
  config="$(gkvm_docs_config "$dir")"
  gkvm_step "generating docs for $kind $dir (${config#"$GKVM_ROOT"/})"
  terraform-docs -c "$config" "$dir" >/dev/null
done < <(gkvm_scopes)
gkvm_info "docs generated"
