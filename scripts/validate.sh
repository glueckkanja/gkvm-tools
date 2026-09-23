#!/usr/bin/env bash
# init -backend=false + validate for the root module, every submodule and
# every example. Needs network access for providers and registry modules,
# but no credentials.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
bin="$(gkvm_binary)"
gkvm_plugin_cache
failed=false
while read -r kind dir; do
  gkvm_step "validating $kind $dir"
  if ! ( "$bin" -chdir="$dir" init -backend=false -input=false -upgrade >/dev/null \
      && "$bin" -chdir="$dir" validate ); then
    failed=true
  fi
done < <(gkvm_scopes)
$failed && gkvm_fail "validation failed"
gkvm_info "all scopes valid"
