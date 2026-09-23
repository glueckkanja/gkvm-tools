# gkvm-tools make targets.
#
# Every target is a thin call into scripts/<target>.sh so the same code runs
# locally (./gkvm <target>), inside the devcontainer and in GitHub Actions.
# Run from the root of a GKVM module repository.

SHELL := /bin/bash
GKVM_HOME ?= $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
export GKVM_HOME

RUN = $(GKVM_HOME)/scripts/$(1).sh

.PHONY: help
help:
	@echo "gkvm targets:"
	@echo "  pre-commit       fmt + fix + docs (writes files)"
	@echo "  pr-check         everything CI runs, read-only"
	@echo "  fmt / fmtcheck   terraform fmt"
	@echo "  fix / fixcheck   avmfix block ordering + terrafmt for markdown"
	@echo "  docs / docscheck terraform-docs"
	@echo "  validate         init -backend=false + validate for every scope"
	@echo "  tflint           tflint with the profile rulesets"
	@echo "  test-unit        tofu test tests/unit (mock providers)"
	@echo "  test-integration tofu test tests/integration (needs credentials)"
	@echo "  test-examples    plan (or apply+destroy with GKVM_E2E=1) every example"
	@echo "  zizmor           audit .github/workflows"
	@echo "  profile          print the detected profile"
	@echo "  versions         print tool versions"

.PHONY: pre-commit
pre-commit:
	@$(call RUN,pre-commit)

.PHONY: pr-check
pr-check:
	@$(call RUN,pr-check)

.PHONY: fmt
fmt:
	@$(call RUN,fmt)

.PHONY: fmtcheck
fmtcheck:
	@$(call RUN,fmtcheck)

.PHONY: fix
fix:
	@$(call RUN,fix)

.PHONY: fixcheck
fixcheck:
	@$(call RUN,fixcheck)

.PHONY: docs
docs:
	@$(call RUN,docs)

.PHONY: docscheck
docscheck:
	@$(call RUN,docscheck)

.PHONY: validate
validate:
	@$(call RUN,validate)

.PHONY: tflint
tflint:
	@$(call RUN,tflint)

.PHONY: test-unit
test-unit:
	@$(call RUN,test-unit)

.PHONY: test-integration
test-integration:
	@$(call RUN,test-integration)

.PHONY: test-examples
test-examples:
	@$(call RUN,test-examples)

.PHONY: zizmor
zizmor:
	@$(call RUN,zizmor)

.PHONY: profile
profile:
	@$(call RUN,profile)

.PHONY: list-examples
list-examples:
	@$(call RUN,list-examples)

.PHONY: versions
versions:
	@$(call RUN,versions)
