#!/usr/bin/env bash
# Writes files: fmt -> fix -> docs. Run before every commit.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
here="$(dirname "${BASH_SOURCE[0]}")"
"$here/fmt.sh"
"$here/fix.sh"
"$here/docs.sh"
gkvm_info "pre-commit done"
