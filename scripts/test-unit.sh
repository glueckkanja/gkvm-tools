#!/usr/bin/env bash
# tofu test over tests/unit. Unit tests use mock_provider blocks and need no
# credentials. Skipped with a notice when the directory has no tests.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
bin="$(gkvm_binary)"
dir="${GKVM_UNIT_TEST_DIR:-tests/unit}"
if ! ls "$dir"/*.tftest.hcl >/dev/null 2>&1; then
  gkvm_warn "no $dir/*.tftest.hcl, skipping unit tests"
  exit 0
fi
gkvm_plugin_cache
gkvm_info "unit tests in $dir with $bin"
"$bin" init -backend=false -input=false -test-directory="$dir" >/dev/null
"$bin" test -test-directory="$dir"
