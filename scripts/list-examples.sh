#!/usr/bin/env bash
# Print the runnable examples as a JSON array of directory names, for use as
# a GitHub Actions matrix. Examples with an .e2eignore marker are excluded.
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
names=()
while read -r dir; do
  gkvm_example_ignored "$dir" && continue
  names+=("$(basename "$dir")")
done < <(gkvm_examples)
printf '%s\n' "${names[@]}" | sed '/^$/d' | jq -R . | jq -cs .
