# CI/CD workflows

Four workflows. `validate` -> `plan` -> `apply` are **chained with `workflow_run`**.
Only the **affected** `cloud/stage` combos run, and apply **promotes dev -> test -> prod**:
dev applies directly, test and prod each require manual approval. `bootstrap` and `destroy` are
**manual-only** (`workflow_dispatch`), never part of the chain.

```
PR        -> detect -> validate -> test                                 (affected combos; plan comments on PR)
push main -> detect -> validate -> test -> plan -> apply-dev -> apply-test -> apply-prod (test & prod: manual approval)

manual    -> iac-destroy.yml (pick cloud + stage) -> destroy-all         (gated by environment: <stage>)
```

| Workflow | Trigger | Jobs |
|---|---|---|
| `iac-validate.yml` | PR + push `main` | `detect` -> `validate` -> `test` |
| `iac-plan.yml` | on `iac-validate` success | `load` -> `plan` (comments plan on PRs) |
| `iac-apply.yml` | on `iac-plan` success, `head_branch == main` | `load` -> `apply-dev` -> `apply-test` -> `apply-prod` |
| `iac-bootstrap.yml` | **manual only** (`workflow_dispatch`) | `bootstrap` (creates the state backend) |
| `iac-destroy.yml` | **manual only** (`workflow_dispatch`) | `destroy` (destroys ALL stacks of the selected cloud/stage) |

The CI calls the **same `make` targets** used locally (single source of truth). Only Trivy and
Checkov run as dedicated marketplace actions.

> **Bootstrap.** The state backend (`iac/bootstrap/<cloud>/<stage>`: RG + storage account +
> container, local backend) lives **outside `live/`**. Create it **once** with `make bootstrap`
> locally, or via the **manual** `iac-bootstrap.yml` workflow (`workflow_dispatch`). It is run-once:
> the local backend state is not persisted across CI runs, so re-running after the resources exist
> will fail. The chained CI pipeline only manages the app stacks under `live/`.

## Affected-only execution

`detect` runs [`.github/scripts/affected.sh`](../scripts/affected.sh) which diffs the change set and
emits a matrix of only the impacted combos:

- `iac/live/<cloud>/<stage>/**` changed -> that combo.
- `iac/modules/<cloud>/**` changed -> all stages of that cloud.
- A global file (`iac/live/terragrunt.hcl`, `iac/.tflint.hcl`, `Makefile`, `.github/**`) changed -> all combos.
- `workflow_dispatch` -> all existing combos.

The matrix is uploaded as the `affected` artifact and consumed downstream across the `workflow_run`
chain (`actions/download-artifact` with `run-id`). If nothing is affected, downstream jobs are
skipped.

## Promotion dev -> test -> prod

`apply-dev` runs first (no approval); `apply-test` only runs after dev **succeeded or was
skipped** (`test`-only change), and `apply-prod` only runs after test **succeeded or was
skipped** (`prod`-only change). Test and prod are gated by `environment: test` / `environment:
prod` (each with required reviewers => manual approval).

## Manual destroy

`iac-destroy.yml` is **manual only** (`workflow_dispatch`, never triggered by push/PR). You pick
`cloud` and `stage` from dropdowns when launching it from the Actions tab (or via
`gh workflow run iac-destroy.yml -f cloud=azure -f stage=<stage>`), and it runs
`make destroy-all` against **every stack** in `iac/live/<cloud>/<stage>/` — i.e. it tears down the
**complete** selected environment, not a single unit.

It reuses `environment: ${{ inputs.stage }}`, the same gate as apply. `apply-dev` runs without
approval on purpose (fast iteration), but destroying `dev` is just as irreversible as destroying
`test`/`prod` — so add **required reviewers to the `dev` environment** too (see below) if you want
every destroy, including dev, to require manual approval.

## Repo settings required

Auth is **service-principal + client secret**: the `azurerm` provider authenticates directly from the
`ARM_*` env vars (no `azure/login`, no `az` CLI, no OIDC / federated credentials).

### 1. Secrets (Settings -> Secrets and variables -> Actions -> **Repository** secrets)

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

### 2. Environments (Settings -> Environments)

- `dev` -> optional reviewers (applies directly, no gate). Add **required reviewers** here if you
  also want `iac-destroy.yml` (stage=dev) to require manual approval — apply-dev will keep
  applying without a gate either way, only `workflow_dispatch` jobs (destroy, bootstrap) are
  affected.
- `test` -> add **required reviewers** so `apply-test` / destroy (stage=test) wait for **manual
  approval**.
- `prod` -> add **required reviewers** so `apply-prod` / destroy (stage=prod) wait for **manual
  approval**. Scope per-environment secrets here if dev/test/prod use different subscriptions.

### 3. Branch protection (on `main`)

- Require a pull request before merging.
- **Required status checks**: `validate`, `test`, `plan`.
  With the matrix, check names include the combo (e.g. `validate (azure, dev)`).
- Require branches to be up to date before merging.

### 4. Actions settings (Settings -> Actions -> General)

- **Allowed actions**: permit `actions/*`, `opentofu/*`, `gruntwork-io/*`, `terraform-linters/*`,
  `azure/*`, `aquasecurity/*`, `bridgecrewio/*`, `marocchino/*` (or allow all).
- Workflow permissions: default is fine - each workflow declares its own (`id-token: write`,
  `pull-requests: write`, `actions: read`).
- `workflow_run` workflows run with the definition from the **default branch**: changes to those YAML
  files only take effect once merged.

## Multi-cloud

The matrix is `cloud x stage` and the `Makefile` derives `LIVE_DIR := iac/live/$(CLOUD)/$(STAGE)`.
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
