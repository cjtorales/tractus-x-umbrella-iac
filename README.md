# tractus-x-umbrella-iac

Infrastructure as Code for Tractus-X Umbrella, managed with **OpenTofu** + **Terragrunt**.
Modular, multi-cloud- and multi-stage-ready, with a chained CI/CD pipeline that runs only the
affected stacks and promotes changes through stages with a manual gate.

The whole pipeline uses the `tofu` binary: every `terragrunt.hcl` sets
`terraform_binary = "tofu"` and providers come from the OpenTofu registry.

## Structure

```
iac/
├── modules/<cloud>/         # Reusable modules
│   ├── resource-group/      # Resource group
│   ├── remote-state/        # State backend (storage + container)
│   ├── networking/          # Network, subnet, security group
│   ├── identity/            # Managed identity
│   ├── dns/                 # DNS zone
│   └── cluster/             # Managed Kubernetes cluster: system + workloads pools, autoscaler
└── live/<cloud>/<stage>/    # Terragrunt stacks (one state per folder)
    ├── resource-group/      # local backend (bootstrap)
    ├── remote-state/        # local backend (bootstrap)
    ├── networking/
    ├── identity/
    ├── dns/
    └── cluster/             # depends on resource-group + networking + identity
```

## Prerequisites

Install locally (with your tool manager of choice, e.g. `asdf` / `mise`, or manually):

| Tool | Version |
|---|---|
| OpenTofu | 1.9.0 |
| Terragrunt | 0.69.0 |
| TFLint | 0.52.0 |
| Trivy | latest |
| Checkov | latest |

> CI pins its own versions in each workflow's `env:` block — keep them in sync.

```bash
make tools            # prints installed tofu / terragrunt / tflint versions

# Authenticate to your cloud and export the credentials the provider needs
# (e.g. the subscription/account id):
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
```

## Bootstrap (one-time)

The `resource-group` and `remote-state` stacks create the resource group and the state Storage
Account, and use a **local backend**. They are a **one-time, run-locally** step (their local state
is not persisted in CI). Everything else uses the remote backend they create.

```bash
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
make bootstrap        # apply resource-group + remote-state (once, locally)
```

After bootstrap, the app stacks (`networking`, `identity`, `dns`, `cluster`) reference the resource
group **by name** (from `env.hcl`), not via a state dependency — so CI never needs the bootstrap
state. The CI lifecycle commands (`plan-all` / `apply-all`) **exclude** the bootstrap stacks.

## Commands (Makefile)

```bash
make help                       # list targets
make fmt-check lint             # formatting + tflint
make bootstrap                  # one-time: RG + state storage (local)
make plan-all                   # plan the app stacks (bootstrap excluded)
make UNIT=cluster plan          # plan a single stack
make apply-all                  # apply the app stacks (bootstrap excluded)
make trivy checkov              # security + compliance
```

## Importing existing resources

Every stack has a `generate "imports"` block with OpenTofu `import {}` blocks, **gated by
`TG_ENABLE_IMPORT`**. Resource IDs are built from the exported subscription/account id (no extra
CLI calls).

```bash
export ARM_SUBSCRIPTION_ID="<SUBSCRIPTION_ID>"
make import          # resource-group and remote-state first, then the rest
make verify-import   # expects "No changes" across all stacks
```

If a `plan` shows drift, adjust the **code** to match the live resource before applying.

## CI/CD

Three workflows in `.github/workflows/`, **chained with `workflow_run`** (cloud OIDC login).
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

> - New `cloud/stage` combos light up automatically once their `iac/live/<cloud>/<stage>/` stacks
>   are created — no workflow edits needed for a new stage of an existing cloud.
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
- **Identity → cluster**: the cluster consumes the `identity` module's managed identity and is granted
  the network role on the subnet (CNI requirement).
- **Terragrunt hooks**: `before_hook` `tofu validate` and `after_hook` `tofu test` on `apply`.
- **Import gated by `TG_ENABLE_IMPORT`**: `imports.tf` is generated at runtime, not versioned.
