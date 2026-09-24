#!/usr/bin/env bash
# Plan every example (smoke test). With GKVM_E2E=1 the example is applied and
# always destroyed afterwards. GKVM_EXAMPLE restricts the run to one example.
# pre.sh / post.sh hooks in the example directory are honoured, as in AVM.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
bin="$(gkvm_binary)"
gkvm_plugin_cache
e2e="${GKVM_E2E:-0}"

# A per-run suffix, handed to every example as TF_VAR_gkvm_suffix. An example
# that needs unique names declares `variable "gkvm_suffix"` and builds them from
# it; examples that do not declare it ignore the variable silently.
#
# This exists because a `random_string` cannot be used for a name that ends up in
# a `for_each` key: those must be known at plan time, and a resource attribute is
# not. The suffix is a plain input, so it is.
if [ -z "${GKVM_SUFFIX:-}" ]; then
  GKVM_SUFFIX="$(od -An -tx1 -N3 /dev/urandom | tr -d ' \n')"
fi
export TF_VAR_gkvm_suffix="$GKVM_SUFFIX"
gkvm_info "example name suffix: $GKVM_SUFFIX"
only="${GKVM_EXAMPLE:-}"
failed=false
run_example() {
  local dir="$1" rc=0
  gkvm_step "example $dir (${e2e/1/apply+destroy})"
  gkvm_run_hook "$dir" pre.sh
  "$bin" -chdir="$dir" init -input=false -upgrade >/dev/null || return 1
  if [ "$e2e" = "1" ]; then
    "$bin" -chdir="$dir" apply -input=false -auto-approve || rc=1
    "$bin" -chdir="$dir" destroy -input=false -auto-approve || rc=1
  else
    "$bin" -chdir="$dir" plan -input=false -lock=false || rc=1
  fi
  gkvm_run_hook "$dir" post.sh
  return $rc
}
while read -r dir; do
  [ -n "$only" ] && [ "$(basename "$dir")" != "$only" ] && continue
  if gkvm_example_ignored "$dir"; then gkvm_warn "skipping $dir (.e2eignore)"; continue; fi
  run_example "$dir" || failed=true
done < <(gkvm_examples)
$failed && gkvm_fail "example run failed"
gkvm_info "examples ok"
