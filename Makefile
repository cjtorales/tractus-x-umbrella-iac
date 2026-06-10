# Makefile — Tractus-X Umbrella IaC (OpenTofu + Terragrunt)
# Groups the lifecycle commands.

# Cloud provider (azure | aws | gcp)
CLOUD ?= $(CLOUD)
# Stage (dev | prod)
STAGE ?= $(STAGE)
# Deployment unit (resource-group | remote-state | networking | identity | dns | cluster)
UNIT  ?= $(DEPLOYMENT_UNIT)

LIVE_DIR := iac/live/$(CLOUD)/$(STAGE)
WORK_DIR := $(LIVE_DIR)/$(UNIT)

TG := terragrunt
TF := tofu                     # terraform_binary = "tofu" in the terragrunt.hcl files
TGI := --terragrunt-non-interactive

# Bootstrap stacks (RG + state storage) use a local backend and are created once
# via `make bootstrap`. CI lifecycle commands exclude them and target only the app
# stacks against the already-existing remote backend.
EXCLUDE_BOOTSTRAP := --terragrunt-exclude-dir "**/resource-group" --terragrunt-exclude-dir "**/remote-state"

ARM_SUBSCRIPTION_ID ?=${ARM_SUBSCRIPTION_ID}
ARM_TENANT_ID       ?=${ARM_TENANT_ID}
ARM_CLIENT_ID       ?=${ARM_CLIENT_ID}
ARM_CLIENT_SECRET   ?=${ARM_CLIENT_SECRET}

.DEFAULT_GOAL := help
.PHONY: help tools check-env require-unit az-login bootstrap \
        fmt fmt-check lint \
        plan apply destroy output \
        validate-all test-all plan-all apply-all destroy-all \
        import verify-import trivy checkov

help:  ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

tools:  ## Show tofu / terragrunt / tflint versions
	@$(TF) version | head -1; $(TG) --version | head -1; tflint --version | head -1

check-env:  ## Require ARM_SUBSCRIPTION_ID
	@test -n "$(ARM_SUBSCRIPTION_ID)" || { echo "ERROR: export ARM_SUBSCRIPTION_ID"; exit 1; }

require-unit:
	@test -n "$(UNIT)" || { echo "ERROR: set UNIT=<resource-group|remote-state|networking|identity|dns|cluster>"; exit 1; }

az-login:  ## Login with a Service Principal
	@az login --service-principal -u "$(ARM_CLIENT_ID)" -p "$(ARM_CLIENT_SECRET)" --tenant "$(ARM_TENANT_ID)" >/dev/null
	@az account set --subscription "$(ARM_SUBSCRIPTION_ID)"

fmt:  ## Format HCL + TF
	@$(TG) hclfmt --terragrunt-working-dir iac/live
	@$(TF) fmt -recursive iac/modules

fmt-check:  ## Check formatting without modifying
	@$(TG) hclfmt --terragrunt-check --terragrunt-working-dir iac/live
	@$(TF) fmt -check -recursive iac/modules

lint:  ## TFLint
	@tflint --chdir iac --recursive

plan: require-unit check-env  ## plan a single UNIT
	@$(TG) plan --terragrunt-working-dir $(WORK_DIR)

apply: require-unit check-env  ## apply a single UNIT
	@$(TG) apply $(TGI) --terragrunt-working-dir $(WORK_DIR)

destroy: require-unit check-env  ## destroy a single UNIT
	@$(TG) destroy --terragrunt-working-dir $(WORK_DIR)

output: require-unit  ## outputs of a single UNIT
	@$(TG) output --terragrunt-working-dir $(WORK_DIR)

validate-all: check-env  ## run-all validate (skips backend; static check)
	@TG_DISABLE_BACKEND=true $(TG) run-all validate $(TGI) --terragrunt-working-dir $(LIVE_DIR)

test-all: check-env  ## run-all test (native module tests; skips backend)
	@TG_DISABLE_BACKEND=true $(TG) run-all test $(TGI) --terragrunt-working-dir $(LIVE_DIR)

bootstrap: check-env  ## One-time: create RG + state storage (run locally; local state)
	@$(TG) apply $(TGI) --terragrunt-working-dir $(LIVE_DIR)/resource-group
	@$(TG) apply $(TGI) --terragrunt-working-dir $(LIVE_DIR)/remote-state

plan-all: check-env  ## run-all plan (app stacks; bootstrap excluded)
	@$(TG) run-all plan $(TGI) $(EXCLUDE_BOOTSTRAP) --terragrunt-working-dir $(LIVE_DIR)

apply-all: check-env  ## run-all apply (app stacks; bootstrap excluded)
	@$(TG) run-all apply $(TGI) $(EXCLUDE_BOOTSTRAP) --terragrunt-working-dir $(LIVE_DIR)

destroy-all: check-env  ## run-all destroy (app stacks; bootstrap excluded)
	@$(TG) run-all destroy $(TGI) $(EXCLUDE_BOOTSTRAP) --terragrunt-working-dir $(LIVE_DIR)

import: check-env  ## Import live resources (bootstrap first, then app stacks)
	@TG_ENABLE_IMPORT=true $(TG) apply $(TGI) --terragrunt-working-dir $(LIVE_DIR)/resource-group
	@TG_ENABLE_IMPORT=true $(TG) apply $(TGI) --terragrunt-working-dir $(LIVE_DIR)/remote-state
	@TG_ENABLE_IMPORT=true $(TG) run-all apply $(TGI) $(EXCLUDE_BOOTSTRAP) --terragrunt-working-dir $(LIVE_DIR)

verify-import: check-env  ## Post-import idempotency check (expects "No changes")
	@$(TG) run-all plan $(TGI) $(EXCLUDE_BOOTSTRAP) --terragrunt-working-dir $(LIVE_DIR)

trivy:  ## Trivy IaC scan (HIGH/CRITICAL)
	@trivy config iac/ --severity HIGH,CRITICAL --exit-code 1

checkov:  ## Checkov compliance scan
	@checkov -d iac/ --framework terraform --compact --config-file .checkov.yaml
