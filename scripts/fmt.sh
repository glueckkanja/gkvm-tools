#!/usr/bin/env bash
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
bin="$(gkvm_binary)"
gkvm_info "formatting with $bin fmt"
"$bin" fmt -recursive
