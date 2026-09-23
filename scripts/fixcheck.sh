#!/usr/bin/env bash
# Run `fix` against a scratch copy and fail on any difference, so the check is
# read-only and works without a clean git tree.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
scratch="$(mktemp -d -t gkvm-fixcheck-XXXXXX)"
trap 'rm -rf "$scratch"' EXIT
tar --exclude=.git --exclude=.terraform --exclude='*.tfstate*' -cf - . | tar -xf - -C "$scratch"
( cd "$scratch" && "$GKVM_HOME/scripts/fix.sh" >/dev/null )
if ! diff -rq --exclude=.git --exclude=.terraform --exclude='*.tfstate*' . "$scratch" >/dev/null; then
  diff -ru --exclude=.git --exclude=.terraform --exclude='*.tfstate*' . "$scratch" || true
  gkvm_fail "fix drift; run 'gkvm fix' (or 'gkvm pre-commit') and commit"
fi
gkvm_info "no fix drift"
