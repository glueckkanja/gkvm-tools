# Templates for module repositories

Copy into a GKVM module repository:

| File | Purpose |
|---|---|
| `.github/workflows/pr-check.yml` | calls the reusable checks |
| `.github/workflows/release.yml` | GitHub release on a semver tag |
| `.github/workflows/sweep-github-sandbox.yml` | deletes leftovers of cancelled GitHub e2e runs; only for a repository that runs `examples: e2e` against a sandbox organisation, and only one per organisation |
| `gkvm`, `gkvm.ps1` | local wrapper: `./gkvm pre-commit`, `./gkvm pr-check` |
| `.gkvm.yml` | optional settings (profile, binary) |
| `.gkvm/tflint.*.override.hcl` | optional tflint overrides |
| `.devcontainer/devcontainer.json` | VS Code devcontainer on the same image |
| `gitignore.snippet` | entries to merge into `.gitignore` |

Then delete the AVM leftovers: `Makefile`, `avm`, `avm.bat`, `avm.ps1`, `.github/actions/*`, `.github/policies/*`, and the old workflows.
