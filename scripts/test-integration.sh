#!/usr/bin/env bash
# tofu test over tests/integration against real providers. Needs credentials
# in the environment (ARM_* for azure, GITHUB_TOKEN/GITHUB_OWNER for github).
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
bin="$(gkvm_binary)"
dir="${GKVM_INTEGRATION_TEST_DIR:-tests/integration}"
if ! ls "$dir"/*.tftest.hcl >/dev/null 2>&1; then
  gkvm_warn "no $dir/*.tftest.hcl, skipping integration tests"
  exit 0
fi
gkvm_plugin_cache
gkvm_info "integration tests in $dir with $bin"
"$bin" init -backend=false -input=false -test-directory="$dir" >/dev/null
"$bin" test -test-directory="$dir"
