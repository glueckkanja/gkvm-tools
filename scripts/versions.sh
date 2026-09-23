#!/usr/bin/env bash
# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
for t in tofu terraform tflint terraform-docs terrafmt avmfix hclmerge zizmor; do
  if command -v "$t" >/dev/null; then
    printf '%-16s %s\n' "$t" "$("$t" --version 2>/dev/null | head -n1 || "$t" version 2>/dev/null | head -n1)"
  else
    printf '%-16s missing\n' "$t"
  fi
done
