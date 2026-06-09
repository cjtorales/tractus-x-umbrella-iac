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
Only the **affected** `cloud/stage` combos run, and apply **promotes dev → prod** with a manual gate:

```
PR        → detect → validate → test                              (plan comments on PR)
push main → detect → validate → test → plan → apply-dev → apply-prod (manual approval)
```

1. **`iac-validate.yml`**: `detect` (affected combos) → `validate` (`make fmt-check` + `make lint` +
   **Trivy** + **Checkov** + `make validate-all`) → `test` (`make test-all`).
2. **`iac-plan.yml`**: runs `make plan-all` for the affected combos; on PRs **comments the plan**.
3. **`iac-apply.yml`**: `apply-dev` first, then `apply-prod` (`needs: apply-dev`, `environment: prod`
   → **manual approval**). Only on `main`.

The CI calls the **same `make` targets** used locally (single source of truth); only Trivy and
Checkov run as dedicated marketplace actions. Full details (affected detection, promotion,
multi-cloud) in **[`.github/workflows/README.md`](.github/workflows/README.md)**.

> - Today only `{ cloud: azure, stage: dev }` exists; `prod` / other providers light up automatically
>   once their `iac/live/<cloud>/<stage>/` stacks are created.
> - Set up Environments `dev` and `prod` (Settings → Environments); add **required reviewers** to
>   `prod` for the manual gate.
> - `workflow_run` workflows run with the definition from the **default branch** (main).

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
