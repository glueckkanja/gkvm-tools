#!/usr/bin/env bash
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
bin="$(gkvm_binary)"
gkvm_info "checking formatting with $bin fmt"
if ! "$bin" fmt -check -recursive -diff; then
  gkvm_fail "unformatted files found; run 'gkvm fmt'"
fi
