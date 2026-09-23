#!/usr/bin/env bash
# Read-only gauntlet mirroring the CI jobs. Every step runs so one invocation
# reports the full picture; the exit code is non-zero if any step failed.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
here="$(dirname "${BASH_SOURCE[0]}")"
failed=()
for step in fmtcheck fixcheck docscheck validate tflint test-unit zizmor; do
  echo; gkvm_info "[$step]"
  "$here/$step.sh" || failed+=("$step")
done
echo
if [ ${#failed[@]} -gt 0 ]; then gkvm_fail "failed steps: ${failed[*]}"; fi
gkvm_info "pr-check passed"
