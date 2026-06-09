# tractus-x-umbrella-iac

Infrastructure as Code for the **dev** environment of Tractus-X Umbrella on **Azure**
(region `westeurope`), managed with **OpenTofu** + **Terragrunt**.

The whole pipeline uses the `tofu` binary: every `terragrunt.hcl` sets
`terraform_binary = "tofu"` and providers come from the OpenTofu registry
(`source = "opentofu/azurerm"`).

## Structure

```
iac/
├── modules/azure/        # Reusable modules
│   ├── resource-group/   # Resource Group
│   ├── remote-state/     # Storage account + container for the tfstate
│   ├── networking/       # VNet, AKS subnet, NSG and association
│   ├── identity/         # User-assigned managed identity (UAMI)
│   ├── dns/              # Private DNS zone
│   └── cluster/          # AKS: system + workloads node pools, UAMI, autoscaler
└── live/azure/dev/       # Terragrunt stacks (one state per folder)
    ├── resource-group/   # local backend (bootstrap)
    ├── remote-state/     # local backend (bootstrap)
    ├── networking/
    ├── identity/
    ├── dns/
    └── cluster/          # depends on resource-group + networking + identity
```

Cluster spec (doc 04): k8s 1.30, Free tier, system pool `Standard_D2s_v3` x2,
workloads pool `Standard_D4s_v3` x2 with autoscaler, UAMI assigned to AKS.

## Prerequisites

```bash
asdf install          # or: mise install  (tooling pinned in .tool-versions)
make tools            # tofu / terragrunt / tflint

# azurerm v4 REQUIRES the subscription id:
az login
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
```

## Commands (Makefile)

```bash
make help                       # list targets
make fmt-check lint             # formatting + tflint
make plan-all                   # plan all stacks
make UNIT=cluster plan          # plan a single stack
make apply-all                  # apply (ordered by dependencies)
make trivy checkov              # security + compliance
```

## Importing existing resources

Every stack has a `generate "imports"` block with OpenTofu `import {}` blocks, **gated by
`TG_ENABLE_IMPORT`**. Azure IDs are built from `ARM_SUBSCRIPTION_ID` (no `az` calls).

```bash
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
make import          # resource-group and remote-state first, then the rest
make verify-import   # expects "No changes" across all stacks
```

> ⚠️ Import only applies if the live resources are already in `westeurope`. If they are in another
> region, aligning to `westeurope` means recreating, not importing.

If a `plan` shows drift, adjust the **code** to match the live resource before applying.

## CI/CD

Three workflows in `.github/workflows/`, **chained with `workflow_run`** (Azure OIDC login).
Guaranteed order: **validate → plan → apply**.

1. **`iac-validate.yml`** (PR + push main): `validate` job (`make fmt-check` + `make lint` +
   **Trivy** + **Checkov** + `make validate-all`) and `test` job (`make test-all` — native tests for
   the 6 modules under `modules/azure/*/tests`). This is the trigger of the chain.
2. **`iac-plan.yml`**: triggered when `iac-validate` finishes **successfully**. Runs `make plan-all`
   and, if it came from a PR, **comments the plan on the PR** (sticky comment).
3. **`iac-apply.yml`**: triggered when `iac-plan` finishes **successfully** and `head_branch == main`.
   Runs `make apply-all` with `environment: dev` → **waits for approval**.

The CI calls the **same `make` targets** used locally (single source of truth); only Trivy and
Checkov run as dedicated marketplace actions that install their own CLI. The `Makefile` is therefore
shared between local dev and CI — not local-only.

> - Apply only proceeds on `main`; on PRs the chain stops at `plan` (comment).
> - Enable *required reviewers* under **Settings → Environments → dev** so apply asks for approval.
> - `workflow_run` workflows (`plan`/`apply`) run with the definition from the **default branch**
>   (main): changes to those YAML files only take effect once merged.

## Design decisions

- **`terraform_binary = "tofu"`** in the root and in the bootstrap stacks (`resource-group`,
  `remote-state`) that do not include the root.
- **Resource Group managed by IaC** (`resource-group` module). Together with `remote-state` it uses a
  **local** backend (gitignored) to avoid the chicken-and-egg problem: both must exist before the
  storage account that holds the other stacks' state.
- **Variable contract** aligned to the doc: `region`, `environment`, `node_count_system`,
  `node_count_workloads`, `machine_type`.
- **Identity → cluster**: the cluster uses the `identity` module's **UAMI** (`UserAssigned`) and
  assigns it the `Network Contributor` role on the subnet (Azure CNI requirement).
- **Terragrunt hooks**: `before_hook` `tofu validate` and `after_hook` `tofu test` on `apply`.
- **Import gated by `TG_ENABLE_IMPORT`**: `imports.tf` is generated at runtime, not versioned.
