#!/usr/bin/env bash
# tflint per scope with the profile ruleset (root / module / example) merged
# with an optional repository override. Warnings fail the run, as in AVM.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
profile="$(gkvm_profile)"
gkvm_info "tflint with profile '$profile'"
config_root="$(gkvm_tflint_config root)"
config_module="$(gkvm_tflint_config module)"
config_example="$(gkvm_tflint_config example)"
gkvm_tflint_init "$config_root"
gkvm_tflint_init "$config_module"
gkvm_tflint_init "$config_example"
failed=false
while read -r kind dir; do
  case "$kind" in
    root)    config="$config_root" ;;
    module)  config="$config_module" ;;
    example) config="$config_example" ;;
  esac
  gkvm_step "linting $kind $dir"
  if ! tflint --chdir="$dir" --config="$config" --minimum-failure-severity=warning; then
    failed=true
  fi
done < <(gkvm_scopes)
$failed && gkvm_fail "tflint reported findings"
gkvm_info "tflint clean"
