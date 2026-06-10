# CI/CD workflows

Three workflows, **chained with `workflow_run`**. Order: **validate → plan → apply**.
Only the **affected** `cloud/stage` combos run, and apply **promotes dev → prod** with a manual gate.

```
PR        → detect → validate → test                    (affected combos; plan comments on PR)
push main → detect → validate → test → plan → apply-dev → apply-prod (manual approval)
```

| Workflow | Trigger | Jobs |
|---|---|---|
| `iac-validate.yml` | PR + push `main` | `detect` → `validate` → `test` |
| `iac-plan.yml` | on `iac-validate` success | `load` → `plan` (comments plan on PRs) |
| `iac-apply.yml` | on `iac-plan` success, `head_branch == main` | `load` → `apply-dev` → `apply-prod` |

The CI calls the **same `make` targets** used locally (single source of truth). Only Trivy and
Checkov run as dedicated marketplace actions.

> **Bootstrap is out of CI.** The `resource-group` and `remote-state` stacks (RG + state Storage
> Account, local backend) are created **once, locally**, via `make bootstrap`. The CI lifecycle
> targets (`plan-all` / `apply-all`) **exclude** them, so the pipeline only manages the app stacks
> against the already-existing remote backend. See the repo README → *Bootstrap*.

## Affected-only execution

`detect` runs [`.github/scripts/affected.sh`](../scripts/affected.sh) which diffs the change set and
emits a matrix of only the impacted combos:

- `iac/live/<cloud>/<stage>/**` changed → that combo.
- `iac/modules/<cloud>/**` changed → all stages of that cloud.
- a global file (`iac/live/terragrunt.hcl`, `iac/.tflint.hcl`, `Makefile`, `.github/**`) → all combos.
- `workflow_dispatch` → all existing combos.

The matrix is uploaded as the `affected` artifact and consumed downstream across the `workflow_run`
chain (`actions/download-artifact` with `run-id`). If nothing is affected, downstream jobs are
skipped.

## Promotion dev → prod

`apply-dev` runs first; `apply-prod` has `needs: [load, apply-dev]` and only runs after dev
**succeeded or was skipped** (prod-only change). Prod is gated by `environment: prod`.

## Repo settings required

Auth is **service-principal + client secret**: the `azurerm` provider authenticates directly from the
`ARM_*` env vars (no `azure/login`, no `az` CLI, no OIDC / federated credentials).

### 1. Secrets (Settings → Secrets and variables → Actions — **Repository** secrets)

| Secret | Mapped to env | Purpose |
|---|---|---|
| `AZURE_CLIENT_ID` | `ARM_CLIENT_ID` | Service principal app id |
| `AZURE_TENANT_ID` | `ARM_TENANT_ID` | Entra ID tenant |
| `AZURE_SUBSCRIPTION_ID` | `ARM_SUBSCRIPTION_ID` | Target subscription |
| `AZURE_CLIENT_SECRET` | `ARM_CLIENT_SECRET` | Service principal secret |

Must be **Repository** secrets (not Environment) so `validate` / `test` / `plan` (which have no
`environment:`) can read them. `GITHUB_TOKEN` is automatic. Add `GCP_*` / `AWS_*` only when those
clouds are introduced.

The service principal needs the role assignments the stacks require (resource management, role
assignment for the cluster identity, DNS management) on the target scope.

### 2. Environments (Settings → Environments)

- `dev` — optional reviewers.
- `prod` — add **required reviewers** so `apply-prod` waits for **manual approval**. Scope
  per-environment secrets here if dev/prod use different subscriptions.

### 3. Branch protection (on `main`)

- Require a pull request before merging.
- **Required status checks**: `validate`, `test`, `plan`.
  > With the matrix, check names include the combo (e.g. `validate (azure, dev)`).
- Require branches to be up to date before merging.

### 4. Actions settings (Settings → Actions → General)

- **Allowed actions**: permit `actions/*`, `opentofu/*`, `gruntwork-io/*`, `terraform-linters/*`,
  `azure/*`, `aquasecurity/*`, `bridgecrewio/*`, `marocchino/*` (or allow all).
- Workflow permissions: default is fine — each workflow declares its own (`id-token: write`,
  `pull-requests: write`, `actions: read`).
- `workflow_run` workflows run with the definition from the **default branch**: changes to those YAML
  files only take effect once merged.

## Multi-cloud

The matrix is `cloud × stage` and the `Makefile` derives `LIVE_DIR := iac/live/$(CLOUD)/$(STAGE)`.
New combos appear **automatically** once their `iac/live/<cloud>/<stage>/` folder exists (no workflow
edit needed for new stages of an existing cloud). To add a **new provider**:

1. Create its `iac/modules/<cloud>/` and `iac/live/<cloud>/<stage>/` stacks.
2. Add its cloud-auth step (conditional on `matrix.cloud`) to each workflow:

   **GCP**
   ```yaml
   - name: GCP auth
     if: matrix.cloud == 'gcp'
     uses: google-github-actions/auth@v2
     with:
       workload_identity_provider: ${{ secrets.GCP_WIF_PROVIDER }}
       service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
   ```

   **AWS**
   ```yaml
   - name: AWS auth
     if: matrix.cloud == 'aws'
     uses: aws-actions/configure-aws-credentials@v4
     with:
       role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
       aws-region: ${{ secrets.AWS_REGION }}
   ```
3. Add the provider secrets.
4. **Generalize `make check-env`**: today it requires `ARM_SUBSCRIPTION_ID` (Azure-specific); make it
   per-cloud when adding GCP/AWS.
