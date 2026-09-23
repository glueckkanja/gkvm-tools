#!/usr/bin/env bash
# Audit the repository's own GitHub Actions workflows. Online audits are off so
# the check needs no token and behaves the same locally and in CI.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
if [ ! -d .github ]; then gkvm_warn "no .github directory, skipping zizmor"; exit 0; fi
gkvm_info "zizmor"
zizmor --no-online-audits --persona="${GKVM_ZIZMOR_PERSONA:-regular}" .github
