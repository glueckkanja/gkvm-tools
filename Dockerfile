# syntax=docker/dockerfile:1
# gkvm-tools: every tool the GKVM make targets need, pinned in versions.env.
# Built for linux/amd64 and linux/arm64; signed with cosign on release.

ARG GO_VERSION=1.27
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-bookworm AS gobuild
ARG TARGETOS TARGETARCH
ARG TERRAFMT_VERSION AVMFIX_VERSION HCLMERGE_REF
ENV CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH GOBIN=/out
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    go install "github.com/katbyte/terrafmt@v${TERRAFMT_VERSION}" \
 && go install "github.com/lonegunmanb/avmfix@v${AVMFIX_VERSION}" \
 && go install "github.com/lonegunmanb/hclmerge@${HCLMERGE_REF}"

FROM debian:bookworm-slim AS download
ARG TARGETARCH
ARG TOFU_VERSION TERRAFORM_VERSION TFLINT_VERSION TERRAFORM_DOCS_VERSION ZIZMOR_VERSION
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl unzip && rm -rf /var/lib/apt/lists/*
WORKDIR /out
RUN set -eux; \
    case "$TARGETARCH" in amd64) rust=x86_64 ;; arm64) rust=aarch64 ;; *) echo "unsupported arch $TARGETARCH"; exit 1 ;; esac; \
    curl -fsSLo tofu.zip "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_linux_${TARGETARCH}.zip" && unzip -q tofu.zip tofu && rm tofu.zip; \
    curl -fsSLo terraform.zip "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" && unzip -q terraform.zip terraform && rm terraform.zip; \
    curl -fsSLo tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${TARGETARCH}.zip" && unzip -q tflint.zip tflint && rm tflint.zip; \
    curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${TARGETARCH}.tar.gz" | tar -xz terraform-docs; \
    curl -fsSL "https://github.com/zizmorcore/zizmor/releases/download/v${ZIZMOR_VERSION}/zizmor-${rust}-unknown-linux-gnu.tar.gz" | tar -xz zizmor; \
    chmod +x tofu terraform tflint terraform-docs zizmor

FROM debian:bookworm-slim
LABEL org.opencontainers.image.source="https://github.com/glueckkanja/gkvm-tools" \
      org.opencontainers.image.description="Toolchain for glueckkanja verified Terraform modules (GKVM)" \
      org.opencontainers.image.licenses="MIT"
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl git jq make unzip diffutils \
 && rm -rf /var/lib/apt/lists/* \
 # /src is bind-mounted and owned by the host user; git must not refuse it.
 && git config --system --add safe.directory '*'
COPY --from=download /out/ /usr/local/bin/
COPY --from=gobuild /out/ /usr/local/bin/
COPY Makefile versions.env /opt/gkvm/
COPY scripts/ /opt/gkvm/scripts/
COPY profiles/ /opt/gkvm/profiles/
COPY docker/gkvm /usr/local/bin/gkvm
ENV GKVM_HOME=/opt/gkvm \
    GKVM_IN_CONTAINER=1 \
    TFLINT_PLUGIN_DIR=/opt/gkvm/tflint-plugins \
    TF_PLUGIN_CACHE_DIR=/tmp/gkvm-plugin-cache \
    TF_IN_AUTOMATION=1
# Pre-install every profile's tflint plugins so runs need no GitHub access.
# Attestation verification of the AVM plugin talks to the GitHub API; a
# GITHUB_TOKEN build secret avoids the unauthenticated rate limit.
RUN --mount=type=secret,id=GITHUB_TOKEN \
    set -eux; \
    if [ -f /run/secrets/GITHUB_TOKEN ]; then export GITHUB_TOKEN="$(cat /run/secrets/GITHUB_TOKEN)"; fi; \
    mkdir -p "$TFLINT_PLUGIN_DIR" /tmp/gkvm-plugin-cache; \
    for cfg in /opt/gkvm/profiles/*/tflint.*.hcl; do tflint --init --config="$cfg"; done; \
    chmod -R a+rX "$TFLINT_PLUGIN_DIR"; chmod 1777 /tmp/gkvm-plugin-cache
WORKDIR /src
ENTRYPOINT []
CMD ["gkvm", "help"]
