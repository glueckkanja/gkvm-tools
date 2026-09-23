# gkvm-tools

Toolchain for **glueckkanja verified modules (GKVM)**: Terraform/OpenTofu modules that follow the Azure Verified Modules (AVM) conventions but are not limited to Azure providers.

It replaces the AVM `make` targets and the `mcr.microsoft.com/azterraform` image, whose upstream (`Azure/tfmod-scaffold`, `Azure/avm-terraform-governance`) is archived. Everything here is owned by glueckkanja, pinned, signed, and works for `azurerm`/`azapi` as well as `integrations/github` or any other provider.

## What you get

| Piece | Where | Purpose |
|---|---|---|
| Container image | `ghcr.io/glueckkanja/gkvm-tools` | every tool, versions pinned in `versions.env`, cosign-signed |
| Make targets | `Makefile`, `scripts/` | `pre-commit`, `pr-check`, `fmt`, `fix`, `docs`, `validate`, `tflint`, `test-*` |
| Profiles | `profiles/{base,azure,github}` | tflint rulesets per provider family, terraform-docs default |
| Reusable workflows | `.github/workflows/terraform-module.yml`, `release.yml` | the CI a module repository calls |
| Templates | `templates/` | files to drop into a module repository |
| Fixtures | `fixtures/` | minimal modules the image is self-tested against |

## Using it in a module repository

1. Copy `templates/` into the repository (see `templates/README.md`).
2. Run `./gkvm pre-commit` once and commit the result. avmfix and terrafmt will reorder blocks the first time.
3. Open a pull request; the `PR Check` workflow runs the same targets inside the image.

```text
./gkvm pre-commit   # fmt + fix + docs, writes files
./gkvm pr-check     # everything CI runs, read-only
./gkvm tflint       # a single target
./gkvm help
```

The wrapper runs the image with Docker (or `CONTAINER_RUNTIME=podman`). Inside the devcontainer the same commands run natively.

## Targets

| Target | Writes | What it does |
|---|---|---|
| `fmt` / `fmtcheck` | yes / no | `tofu fmt -recursive` |
| `fix` / `fixcheck` | yes / no | `avmfix` block ordering for root, `modules/*`, `examples/*`; `terrafmt` for HCL in markdown |
| `docs` / `docscheck` | yes / no | `terraform-docs` for every scope; check uses `--output-check` and never writes |
| `validate` | no | `init -backend=false` + `validate` for every scope |
| `tflint` | no | profile ruleset per scope kind (root, module, example); warnings fail |
| `test-unit` | no | `tofu test -test-directory=tests/unit` (mock providers, no credentials) |
| `test-integration` | no | `tofu test -test-directory=tests/integration` (real providers) |
| `test-examples` | no | `plan` every example; `GKVM_E2E=1` applies and always destroys; `.e2eignore` skips |
| `zizmor` | no | audit `.github/` |
| `pre-commit` | yes | `fmt`, `fix`, `docs` |
| `pr-check` | no | `fmtcheck`, `fixcheck`, `docscheck`, `validate`, `tflint`, `test-unit`, `zizmor` |

Scopes are the repository root, every `modules/*` and every `examples/*` directory that contains `.tf` files.

## Profiles

The profile is detected from the root `required_providers`: `azurerm`, `azapi` or `azuread` selects **azure**, `integrations/github` selects **github**, anything else **base**. Override with `GKVM_PROFILE` or `profile:` in `.gkvm.yml`.

- **base**: `tflint-ruleset-terraform` (recommended preset plus the AVM-era generic rules). Structural conventions (variables in `variables*.tf`, outputs in `outputs*.tf`, ordering) are enforced by `avmfix`.
- **azure**: base plus `Azure/tflint-ruleset-avm` v1. Rules the fleet already complies with are blocking. Rules AVM added later run at severity `notice`: reported, not blocking. Promote them per repository with an override. `avm_provider_azurerm_disallowed` and `avm_provider_modtm_version_constraint` are off by policy: GKVM modules use azurerm and ship no Microsoft telemetry.
- **github**: base. No provider-specific ruleset exists yet.

Overrides: `.gkvm/tflint.{root,module,example}.override.hcl` is merged over the profile file with `hclmerge` (override semantics). The legacy AVM names `avm.tflint.override.hcl`, `avm.tflint_module.override.hcl` and `avm.tflint_example.override.hcl` still work.

terraform-docs config resolution per scope: `<scope>/.terraform-docs.yml`, then the parent directory (`examples/`, `modules/`), then the repository root, then the profile default.

## CI

`terraform-module.yml` runs every job inside the image, so CI and laptop execute the same scripts.

| Job | Credentials | Runs |
|---|---|---|
| static | none | fmtcheck, fixcheck, docscheck, tflint, zizmor |
| validate | none | validate |
| unit | none | test-unit |
| discover + examples | `environment: test` | `plan` (`examples: smoke`) or apply and destroy (`examples: e2e`) per example, matrix |
| complete | none | single required status check |

Inputs: `profile` (auto), `binary` (tofu), `examples` (off), `environment` (test), `image`, `runs-on`.

Callers use `secrets: inherit`: the per-repository `ARM_CLIENT_ID_OVERRIDE`, `ARM_TENANT_ID_OVERRIDE` and `ARM_SUBSCRIPTION_ID_OVERRIDE` secrets live on the `test` environment and only resolve inside the called job that declares that environment. They win over the organisation-wide `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`. Azure examples authenticate with OIDC: the providers exchange the Actions token themselves (`ARM_USE_OIDC=true`) using the organisation secrets `ARM_CLIENT_ID`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`. The Entra app needs a federated credential whose subject matches `repo:glueckkanja/<repo>:environment:test`, or one flexible federated credential matching all GKVM repositories. GitHub examples use `GKVM_GITHUB_TOKEN` (secret) and `GKVM_GITHUB_OWNER` (variable) for a sandbox organisation.

`release.yml` publishes a GitHub release with generated notes on a `vX.Y.Z` tag; tags with a hyphen become pre-releases.

## Image

Built by `release-image.yml` for `linux/amd64` and `linux/arm64` on every `vX.Y.Z` tag, pushed to GHCR with the tags `X.Y.Z`, `X.Y`, `vX` (currently `v0`) and `sha-…`, signed with cosign (keyless) and attested with build provenance.

Verify a pull:

```bash
cosign verify ghcr.io/glueckkanja/gkvm-tools:v0 \
  --certificate-identity-regexp='^https://github.com/glueckkanja/gkvm-tools/' \
  --certificate-oidc-issuer=https://token.actions.githubusercontent.com
```

Releasing: bump `versions.env` if needed, set the `image` default in `.github/workflows/terraform-module.yml` to the new version, commit, tag `vX.Y.Z`, push the tag. Then pin `templates/` to the tag's commit SHA in a follow-up commit.

Tools inside (`gkvm versions`): OpenTofu, Terraform, tflint (plugins pre-installed for every profile), terraform-docs, terrafmt, avmfix, hclmerge, zizmor, git, jq, make. Versions live in `versions.env`; bump them in a pull request, tag, done.

## Developing gkvm-tools

`ci.yml` runs shellcheck and zizmor, builds the image for the runner and runs `pr-check` and `pre-commit` against every directory in `fixtures/`. To run the scripts without the image:

```bash
export GKVM_HOME=$PWD
cd fixtures/github-basic
make -f "$GKVM_HOME/Makefile" pr-check
```

## Design notes

- No runtime downloads. AVM's Makefile curled scripts and tflint configs on every run; everything here ships in the image at a pinned version.
- Provider-neutral core, provider-specific profiles. Adding a provider family means adding a `profiles/<name>/` directory and one line in `gkvm_profile`.
- Native `tofu test` instead of the Go-based `avmtester`, so unit and integration tests are written the same way for every provider.
- Read-only checks are really read-only: `docscheck` uses `--output-check`, `fixcheck` diffs a scratch copy.
- Microsoft's replacement, `Avm.Authoring` with the `azure-verified-modules-tools` reusable workflow, stays Azure-bound (metadata schema, managed-file sync, subscription round-robin). Its ideas (pins manifest, verb chain, scope discovery) are reused here without the dependency.
