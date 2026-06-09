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

## Affected-only execution

`detect` runs [`.github/scripts/affected.sh`](../scripts/affected.sh) which diffs the change set and
emits a matrix of only the impacted combos:

- `iac/live/<cloud>/<stage>/**` changed → that combo.
- `iac/modules/<cloud>/**` changed → all stages of that cloud.
- a global file (`iac/live/terragrunt.hcl`, `iac/.tflint.hcl`, `Makefile`, `.tool-versions`,
  `.github/**`) → all combos.
- `workflow_dispatch` → all existing combos.

The matrix is uploaded as the `affected` artifact and consumed downstream across the `workflow_run`
chain (`actions/download-artifact` with `run-id`). If nothing is affected, downstream jobs are
skipped.

## Promotion dev → prod

`apply-dev` runs first; `apply-prod` has `needs: [load, apply-dev]` and only runs after dev
**succeeded or was skipped** (prod-only change). Prod is gated by `environment: prod`.

## Repo settings required

- **Branch protection**: mark `validate` / `test` / `plan` as *required status checks*.
- **Environments** (Settings → Environments):
  - `dev` — optional reviewers.
  - `prod` — add **required reviewers** so `apply-prod` waits for **manual approval**.
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
