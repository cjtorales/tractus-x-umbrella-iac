# Makefile — Tractus-X Umbrella IaC (OpenTofu + Terragrunt)
# Groups the lifecycle commands.

# Cloud provider (azure | aws | gcp)
CLOUD ?= $(CLOUD)
# Stage (dev | prod)
STAGE ?= $(STAGE)
# Deployment unit (networking | identity | dns | aks)
UNIT  ?= $(DEPLOYMENT_UNIT)

LIVE_DIR := iac/live/$(CLOUD)/$(STAGE)
WORK_DIR := $(LIVE_DIR)/$(UNIT)

# Backend bootstrap lives outside live/ (created once via `make bootstrap`).
BOOTSTRAP_DIR := iac/bootstrap/$(CLOUD)/$(STAGE)

TG := terragrunt
TF := tofu                     # terraform_binary = "tofu" in the terragrunt.hcl files
TGI := --terragrunt-non-interactive

ARM_SUBSCRIPTION_ID ?=${ARM_SUBSCRIPTION_ID}
ARM_TENANT_ID       ?=${ARM_TENANT_ID}
ARM_CLIENT_ID       ?=${ARM_CLIENT_ID}
ARM_CLIENT_SECRET   ?=${ARM_CLIENT_SECRET}

.DEFAULT_GOAL := help
.PHONY: help tools check-env require-unit az-login bootstrap \
        fmt fmt-check lint \
        plan apply destroy output \
        validate-all test-all plan-all apply-all destroy-all \
        trivy checkov

help:  ## List available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

tools:  ## Show tofu / terragrunt / tflint versions
	@$(TF) version | head -1; $(TG) --version | head -1; tflint --version | head -1

check-env:  ## Require Azure credentials (all ARM_* vars)
	@missing=""; \
	for v in ARM_CLIENT_ID ARM_CLIENT_SECRET ARM_TENANT_ID ARM_SUBSCRIPTION_ID; do \
		eval "val=\$$$$v"; \
		[ -n "$$val" ] || missing="$$missing $$v"; \
	done; \
	if [ -n "$$missing" ]; then echo "ERROR: missing env vars:$$missing"; exit 1; fi

require-unit:
	@test -n "$(UNIT)" || { echo "ERROR: set UNIT=<networking|identity|dns|aks>"; exit 1; }

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
	@$(TG) apply -auto-approve $(TGI) --terragrunt-working-dir $(WORK_DIR)

destroy: require-unit check-env  ## destroy a single UNIT
	@$(TG) destroy --terragrunt-working-dir $(WORK_DIR)

output: require-unit  ## outputs of a single UNIT
	@$(TG) output --terragrunt-working-dir $(WORK_DIR)

validate-all: check-env  ## run-all validate (skips backend; static check)
	@TG_DISABLE_BACKEND=true $(TG) run-all validate $(TGI) --terragrunt-working-dir $(LIVE_DIR)

test-all:  ## Native tofu tests for every module that has a tests/ folder
	@for d in iac/modules/$(CLOUD)/*/; do \
		[ -d "$${d}tests" ] || continue; \
		echo "== test $${d} =="; \
		( cd "$$d" && $(TF) init -backend=false -input=false -no-color >/dev/null && $(TF) test -no-color ) || exit 1; \
	done

bootstrap: check-env  ## One-time: create RG + state storage (run locally; local state)
	@$(TG) apply -auto-approve $(TGI) --terragrunt-working-dir $(BOOTSTRAP_DIR)

plan-all: check-env  ## run-all plan (app stacks)
	@$(TG) run-all plan $(TGI) --terragrunt-working-dir $(LIVE_DIR)

apply-all: check-env  ## run-all apply (app stacks)
	@$(TG) run-all apply -auto-approve $(TGI) --terragrunt-working-dir $(LIVE_DIR)

destroy-all: check-env  ## run-all destroy (app stacks)
	@$(TG) run-all destroy $(TGI) --terragrunt-working-dir $(LIVE_DIR)

trivy:  ## Trivy IaC scan (HIGH/CRITICAL)
	@trivy config iac/ --severity HIGH,CRITICAL --exit-code 1

checkov:  ## Checkov compliance scan
	@checkov -d iac/ --framework terraform --compact --config-file .checkov.yaml
