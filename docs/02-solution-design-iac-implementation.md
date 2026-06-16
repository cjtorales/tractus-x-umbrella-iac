# Solution Design: IaC Automation Implementation

<!-- TOC -->
* [1. Business Case](#1-business-case)
  * [1.1 Executive Summary](#11-executive-summary)
  * [1.2 Objective](#12-objective)
  * [1.3 Deliverables](#13-deliverables)
  * [1.4 Indicative Action Plan](#14-indicative-action-plan)
  * [1.5 Assumptions and Prerequisites](#15-assumptions-and-prerequisites)
  * [1.6 Limitations](#16-limitations)
* [2. Implementation Architecture](#2-implementation-architecture)
  * [2.1 IaC Automation Flow Diagram](#21-iac-automation-flow-diagram)
  * [2.2 Implemented Terraform Modules](#22-implemented-terraform-modules)
  * [2.3 Module Dependencies Diagram](#23-module-dependencies-diagram)
  * [2.4 Pulumi Role for In-Cluster Resources](#24-pulumi-role-for-in-cluster-resources)
* [3. Provisioning Runbook](#3-provisioning-runbook)
  * [3.1 Prerequisites](#31-prerequisites)
  * [3.2 Phase A — Cluster Provisioning](#32-phase-a--cluster-provisioning)
  * [3.3 Phase B — Base Cluster Configuration](#33-phase-b--base-cluster-configuration)
  * [3.4 Phase C — Validation](#34-phase-c--validation)
  * [3.5 Summarized Execution Example](#35-summarized-execution-example)
  * [3.6 Definition of "Done"](#36-definition-of-done)
  * [3.7 Runbook Sequence Diagram](#37-runbook-sequence-diagram)
* [4. GitHub Actions Pipeline](#4-github-actions-pipeline)
  * [4.1 Complete Pipeline Diagram](#41-complete-pipeline-diagram)
  * [4.2 Optimized Execution on main](#42-optimized-execution-on-main)
  * [4.3 Workflow Example](#43-workflow-example)
* [5. Integrated Validation Tools](#5-integrated-validation-tools)
  * [5.1 Tools Summary](#51-tools-summary)
  * [5.2 TFLint Configuration](#52-tflint-configuration)
  * [5.3 Validation Flow Diagram](#53-validation-flow-diagram)
* [6. Test Suite and Validation Report](#6-test-suite-and-validation-report)
  * [6.1 Infrastructure Test Matrix](#61-infrastructure-test-matrix)
  * [6.2 Native Terraform Tests](#62-native-terraform-tests)
  * [6.3 Test Execution via Terragrunt](#63-test-execution-via-terragrunt)
  * [6.4 Minimum Evidence](#64-minimum-evidence)
  * [6.5 Post-Apply Validation Flow Diagram](#65-post-apply-validation-flow-diagram)
* [7. Common Multi-Cloud Contract](#7-common-multi-cloud-contract)
* [8. Scope and Limitations Alignment](#8-scope-and-limitations-alignment)
* [9. Final Recommendation](#9-final-recommendation)
* [NOTICE](#notice)
<!-- TOC -->

---

## Metadata

* **Date:** 2026
* **Dependencies:** Kubernetes (AKS/GKE/EKS), Terraform, Terragrunt, OpenTofu (alternative), Pulumi (in-cluster resources)
* **Target group:** Platform architecture, DevOps, Infrastructure engineering
* **CI/CD:** GitHub Actions
* **IaC Validation:** TFLint, Trivy, Checkov
* **Prerequisite:** Approved exploration concept

---

# 1. Business Case

## 1.1 Executive Summary

This document describes the implementation of the IaC automation designed in the exploration phase. Its goal is to deliver successfully provisioned IaC components in the target Kubernetes environments, including the automation, the execution runbook, the GitHub Actions pipeline, and the validation test suite.

## 1.2 Objective

| **Objective** | IaC components successfully provided in the target Kubernetes environments per the exploration concept specification. |
|----------|-----------------------------------------------------------------------------------------------------------------------------------|

## 1.3 Deliverables

| # | Deliverable | Description |
|---|-----------|-------------|
| 1 | **IaC Automation** | Terraform + Terragrunt for multi-cloud cluster provisioning |
| 2 | **GitHub Actions Pipeline** | CI/CD with validation, plan and optimized apply |
| 3 | **Execution Guide (Runbook)** | For complete provisioning |
| 4 | **Test suite and report** | Terraform tests via Terragrunt + infrastructure validation |

## 1.4 Indicative Action Plan

1. Development of Terraform modules for each cloud provider (AKS, GKE, EKS)
2. Terragrunt configuration for DRY orchestration between environments
3. GitHub Actions pipeline implementation with optimized execution via `--filter-affected`
4. TFLint, Trivy and Checkov integration in the pipeline
5. Development of native Terraform tests and execution via Terragrunt
6. Automated cluster provisioning in target environments
7. Technical documentation creation (runbook)
8. Test execution for provisioning validation
9. Client review
10. Technical acceptance

## 1.5 Assumptions and Prerequisites

- Access to target cloud environments (Azure, GCP, AWS) is guaranteed
- Necessary permissions for IaC automation execution exist
- The exploration concept is approved and serves as the basis
- GitHub repository with Actions enabled
- Service principals / service accounts configured for CI/CD
- The implementation targets a technical maturity level of **TRL 7**

## 1.6 Limitations

- **No** application deployment within the cluster
- **No** installation of tools like Argo CD, ingress-nginx, etc. (out of scope)
- **No** operation or monitoring of the provided environment
- The IaC automation is designed for execution in provisioned cloud environments

---

# 2. Implementation Architecture

## 2.1 IaC Automation Flow Diagram

```mermaid
flowchart TB
    subgraph "Phase 1: Validation via Terragrunt (CI)"
        TG_VAL["terragrunt run-all validate<br/>--filter-affected"]
        LINT["TFLint"]
        TRIVY["Trivy scan"]
        CHECKOV["Checkov scan"]

        TG_VAL --> LINT --> TRIVY --> CHECKOV
    end

    subgraph "Phase 2: Tests"
        TG_TEST["terragrunt run-all test<br/>(affected modules)"]

        CHECKOV --> TG_TEST
    end

    subgraph "Phase 3: Infrastructure Provisioning"
        PLAN["terragrunt run-all plan<br/>--filter-affected"]
        APPLY["terragrunt run-all apply<br/>(PR approved on main)"]

        TG_TEST --> PLAN --> APPLY
    end

    subgraph "Cloud Resources Created"
        RG["Resource Group / Project / Account"]
        VNET["VNet / VPC + Subnets"]
        CLUSTER["AKS / GKE / EKS Cluster"]
        NODEPOOL_SYS["Node Pool: system"]
        NODEPOOL_WRK["Node Pool: workloads"]
        DNS_ZONE["DNS Zone"]
        IDENTITY["Managed Identity / WI / IAM"]
        STORAGE["Storage (Terraform State)"]

        APPLY --> RG
        RG --> VNET
        VNET --> CLUSTER
        CLUSTER --> NODEPOOL_SYS
        CLUSTER --> NODEPOOL_WRK
        APPLY --> DNS_ZONE
        APPLY --> IDENTITY
        APPLY --> STORAGE
    end

    subgraph "Phase 4: Base Configuration (Optional)"
        KUBECONFIG["Get kubeconfig"]
        NS["Create namespaces"]
        RBAC["Configure RBAC"]
        NP["Apply NetworkPolicies"]
        RQ["Apply ResourceQuotas"]

        CLUSTER --> KUBECONFIG
        KUBECONFIG --> NS
        NS --> RBAC
        NS --> NP
        NS --> RQ
    end

    subgraph "Phase 5: Post-Apply Validation"
        TESTS_POST["terragrunt run-all test"]
        K8S_CHECK["kubectl validations"]
        EVIDENCE["Collect Evidence"]

        RQ --> TESTS_POST
        TESTS_POST --> K8S_CHECK
        K8S_CHECK --> EVIDENCE
    end
```

## 2.2 Implemented Terraform Modules

| Module | Location | Responsibility | Providers |
|--------|----------|----------------|-----------|
| `cluster` | `iac/modules/azure/cluster/` | AKS cluster, node pools | `azurerm` |
| `cluster` | `iac/modules/gcp/cluster/` | GKE cluster, node pools | `google` |
| `cluster` | `iac/modules/aws/cluster/` | EKS cluster, managed node groups | `aws` |
| `networking` | `iac/modules/{provider}/networking/` | VNet/VPC, subnets, security groups | Per-cloud |
| `dns` | `iac/modules/{provider}/dns/` | DNS zone | Per-cloud |
| `identity` | `iac/modules/{provider}/identity/` | Managed Identity / Workload Identity / IAM | Per-cloud |
| `remote-state` | `iac/modules/{provider}/remote-state/` | Remote backend for Terraform state | Per-cloud |
| `pulumi` | `iac/modules/pulumi/` (optional) | In-cluster K8s resources | Kubernetes |

## 2.3 Module Dependencies Diagram

```mermaid
graph TB
    subgraph "Terraform Modules via Terragrunt"
        ROOT_AZ["live/azure/dev/<br/>terragrunt.hcl"]
        ROOT_GCP["live/gcp/dev/<br/>terragrunt.hcl"]
        ROOT_AWS["live/aws/dev/<br/>terragrunt.hcl"]

        MOD_NET["module: networking"]
        MOD_AKS["module: cluster (azure)"]
        MOD_GKE["module: cluster (gcp)"]
        MOD_EKS["module: cluster (aws)"]
        MOD_DNS["module: dns"]
        MOD_ID["module: identity"]

        ROOT_AZ --> MOD_NET
        ROOT_AZ --> MOD_AKS
        ROOT_AZ --> MOD_DNS
        ROOT_AZ --> MOD_ID

        ROOT_GCP --> MOD_NET
        ROOT_GCP --> MOD_GKE
        ROOT_GCP --> MOD_DNS
        ROOT_GCP --> MOD_ID

        ROOT_AWS --> MOD_NET
        ROOT_AWS --> MOD_EKS
        ROOT_AWS --> MOD_DNS
        ROOT_AWS --> MOD_ID

        MOD_NET -->|"vpc_id, subnet_ids"| MOD_AKS
        MOD_NET -->|"vpc_id, subnet_ids"| MOD_GKE
        MOD_NET -->|"vpc_id, subnet_ids"| MOD_EKS

        MOD_ID -->|"identity_id"| MOD_AKS
        MOD_ID -->|"service_account"| MOD_GKE
        MOD_ID -->|"role_arn"| MOD_EKS
    end

    subgraph "Cluster Outputs"
        OUT_ENDPOINT["cluster_endpoint"]
        OUT_CA["ca_certificate"]
        OUT_KUBECONFIG["kubeconfig"]

        MOD_AKS --> OUT_ENDPOINT
        MOD_GKE --> OUT_ENDPOINT
        MOD_EKS --> OUT_ENDPOINT
        MOD_AKS --> OUT_CA
        MOD_GKE --> OUT_CA
        MOD_EKS --> OUT_CA
        MOD_AKS --> OUT_KUBECONFIG
        MOD_GKE --> OUT_KUBECONFIG
        MOD_EKS --> OUT_KUBECONFIG
    end
```

## 2.4 Pulumi Role for In-Cluster Resources

Optionally, **Pulumi** is used to manage internal Kubernetes resources that complement the cluster infrastructure:

```mermaid
flowchart LR
    TF["Terraform + Terragrunt<br/>━━━━━━━━━━<br/>Creates the cluster<br/>Outputs: endpoint, kubeconfig"]

    PULUMI["Pulumi (TypeScript/Go)<br/>━━━━━━━━━━<br/>Consumes kubeconfig<br/>Creates K8s resources"]

    subgraph "In-Cluster Resources"
        NS["Namespaces<br/>dev, staging, prod"]
        RBAC["RBAC<br/>Roles + Bindings<br/>(to estimate per application)"]
        NP["NetworkPolicies<br/>(to define per application)"]
        RQ["ResourceQuotas<br/>(to estimate per application)"]
    end

    TF -->|"kubeconfig"| PULUMI
    PULUMI --> NS
    PULUMI --> RBAC
    PULUMI --> NP
    PULUMI --> RQ
```

---

# 3. Provisioning Runbook

## 3.1 Prerequisites

| Prerequisite | Required | Notes |
|---|---|---|
| Access to target cloud | Yes | Azure, GCP, or AWS |
| Service principal / service account | Yes | For Terraform and GitHub Actions |
| Remote state backend | Yes | Azure Blob / GCS / S3 |
| GitHub repository with Actions | Yes | Automated pipeline |
| Terraform + Terragrunt installed | Yes | For local / CI execution |
| TFLint + Trivy + Checkov | Yes | For validation |

## 3.2 Phase A — Cluster Provisioning

1. Select the environment (`iac/live/azure/dev`, `iac/live/gcp/dev`, etc.)
2. Run `terragrunt run-all init`
3. Run `terragrunt run-all plan --filter-affected` and review changes
4. Run `terragrunt run-all apply --filter-affected`
5. Obtain endpoint, CA, kubeconfig and evidence

## 3.3 Phase B — Base Cluster Configuration

1. Create namespaces per stage (dev, staging, prod) — via Terraform or Pulumi
2. Configure RBAC per namespace (to estimate per application)
3. Apply isolation NetworkPolicies (to define per application)
4. Apply ResourceQuotas (to estimate per application)
5. Verify configuration

## 3.4 Phase C — Validation

1. Run `terragrunt run-all test` to validate modules
2. Verify cluster accessible with `kubectl cluster-info`
3. Verify nodes, namespaces, RBAC
4. Collect evidence for acceptance

## 3.5 Summarized Execution Example

```bash
# Phase A — Provisioning via Terragrunt
cd iac/live/azure/dev
terragrunt run-all init
terragrunt run-all plan --filter-affected
terragrunt run-all apply --filter-affected

# Phase B — Cluster validation
export KUBECONFIG=$(terragrunt output -raw kubeconfig_path)
kubectl cluster-info
kubectl get nodes
kubectl get ns

# Phase B — Base configuration validation
kubectl get networkpolicies -A
kubectl get resourcequotas -A
kubectl auth can-i list pods --namespace=dev --as=dev-user

# Phase C — Terraform tests via Terragrunt
terragrunt run-all test

# Phase C — Final validations
kubectl get nodes -o wide
kubectl top nodes
```

## 3.6 Definition of "Done"

Provisioning is considered technically correct when:

- ✅ The cluster exists and is accessible
- ✅ Node pools are in `Ready` state
- ✅ Namespaces are created with RBAC, NetworkPolicies and ResourceQuotas
- ✅ Terraform tests pass correctly (`terragrunt run-all test`)
- ✅ TFLint, Trivy and Checkov report no critical issues
- ✅ Evidence is archived

## 3.7 Runbook Sequence Diagram

```mermaid
sequenceDiagram
    actor Dev as Dev / Operator
    participant GHA as GitHub Actions
    participant TG as Terragrunt
    participant TF as Terraform
    participant Cloud as Azure / GCP / AWS
    participant K8s as Kubernetes

    rect rgb(230, 245, 255)
        Note over Dev, TG: Phase 1 — Validation via Terragrunt
        Dev->>GHA: Push to main
        GHA->>TG: terragrunt run-all validate --filter-affected
        TG-->>GHA: Results
        GHA->>GHA: TFLint + Trivy + Checkov
        GHA->>TG: terragrunt run-all test
        TG-->>GHA: Test results
    end

    rect rgb(230, 255, 230)
        Note over TG, Cloud: Phase 2 — Provisioning
        GHA->>TG: terragrunt run-all plan --filter-affected
        TG->>TF: terraform plan (per module)
        TF->>Cloud: API calls (read-only)
        Cloud-->>TF: Plan output
        TG-->>GHA: Plan summary
        Dev->>Git: Approve PR and merge to main
        GHA->>TG: terragrunt run-all apply --filter-affected
        TG->>TF: terraform apply (per module)
        TF->>Cloud: Create cluster + networking + DNS
        Cloud-->>TF: Resources created
    end

    rect rgb(255, 245, 230)
        Note over TF, K8s: Phase 3 — Base Configuration
        TF->>K8s: Create namespaces
        TF->>K8s: Configure RBAC
        TF->>K8s: Apply NetworkPolicies
        TF->>K8s: Apply ResourceQuotas
    end

    rect rgb(255, 230, 230)
        Note over GHA, K8s: Phase 4 — Post-Apply Validation
        GHA->>TG: terragrunt run-all test
        GHA->>K8s: kubectl cluster-info
        GHA->>K8s: kubectl get nodes
        K8s-->>GHA: Results
        GHA-->>Dev: Final report
    end
```

---

# 4. GitHub Actions Pipeline

## 4.1 Complete Pipeline Diagram

```mermaid
flowchart TB
    subgraph "Trigger"
        PR["Pull Request<br/>(validation only)"]
        PUSH["Push to main<br/>(validate + plan + apply)"]
    end

    subgraph "Job: Validation via Terragrunt"
        TG_VAL["terragrunt run-all validate<br/>--filter-affected"]
        LINT["TFLint (with cloud plugins)"]
        TRIVY_J["Trivy config scan"]
        CHECKOV_J["Checkov policy scan"]

        TG_VAL --> LINT --> TRIVY_J --> CHECKOV_J
    end

    subgraph "Job: Tests"
        TG_TEST["terragrunt run-all test<br/>(affected modules)"]
    end

    subgraph "Job: Plan"
        TG_PLAN["terragrunt run-all plan<br/>--filter-affected"]
        PR_COMMENT["Comment plan on PR<br/>(if PR)"]
    end

    subgraph "Job: Apply (PR approved on main)"
        TG_APPLY["terragrunt run-all apply<br/>--filter-affected"]
    end

    subgraph "Job: Post-Apply"
        TG_TEST_POST["terragrunt run-all test"]
        K8S_VAL["kubectl validations"]
        REPORT["Generate report"]
    end

    PR --> TG_VAL
    PUSH --> TG_VAL
    CHECKOV_J --> TG_TEST
    TG_TEST --> TG_PLAN
    TG_PLAN --> PR_COMMENT
    TG_PLAN --> TG_APPLY
    TG_APPLY --> TG_TEST_POST
    TG_TEST_POST --> K8S_VAL
    K8S_VAL --> REPORT
```

## 4.2 Optimized Execution on main

Only affected modules are executed, using Terragrunt's `--filter-affected` flag. This flag filters components that have been modified, added, or removed between the default branch (typically `main`) and HEAD. It is equivalent to using `--filter '[main...HEAD]'`:

```mermaid
flowchart TB
    PUSH["Push to main"]
    FILTER["terragrunt run-all plan<br/>--filter-affected<br/>━━━━━━━━━━<br/>Filters modified, added or<br/>removed components between<br/>main and HEAD"]

    subgraph "Result"
        AFFECTED["Only affected modules<br/>+ their dependents<br/>are executed"]
        SKIP["Unchanged modules<br/>are skipped"]
    end

    PUSH --> FILTER
    FILTER --> AFFECTED
    FILTER --> SKIP
```

## 4.3 Workflow Example

```yaml
name: IaC Pipeline

on:
  push:
    branches: [main]
    paths: ['iac/**']
  pull_request:
    paths: ['iac/**']

env:
  TF_VERSION: "1.9.0"
  TG_VERSION: "0.67.0"

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ${{ env.TF_VERSION }}
      - name: Terragrunt Validate (affected only)
        working-directory: iac/live
        run: terragrunt run-all validate --filter-affected
      - name: TFLint
        run: |
          tflint --init --config=iac/.tflint.hcl
          tflint --recursive --config=iac/.tflint.hcl
      - name: Trivy
        run: trivy config iac/ --severity HIGH,CRITICAL --exit-code 1
      - name: Checkov
        run: checkov -d iac/ --framework terraform --compact
      - name: Terragrunt Tests (affected only)
        working-directory: iac/live
        run: terragrunt run-all test --filter-affected

  plan:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Terragrunt Plan (affected only)
        working-directory: iac/live
        run: terragrunt run-all plan --filter-affected --terragrunt-non-interactive

  apply:
    needs: plan
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - name: Terragrunt Apply (affected only)
        working-directory: iac/live
        run: terragrunt run-all apply --filter-affected --terragrunt-non-interactive

  post-apply:
    needs: apply
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Kubectl Validation
        run: |
          kubectl cluster-info
          kubectl get nodes
          kubectl get ns
```

---

# 5. Integrated Validation Tools

## 5.1 Tools Summary

| Tool | Purpose | What it detects | Integration |
|---|---|---|---|
| **TFLint** | HCL linting | Syntax errors, naming, best practices, provider-specific rules | GitHub Actions, pre-commit |
| **Trivy** | IaC security | Security misconfigurations, known vulnerabilities | GitHub Actions |
| **Checkov** | Compliance | CIS, SOC2, HIPAA policies, custom rules | GitHub Actions |

## 5.2 TFLint Configuration

```hcl
# iac/.tflint.hcl
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

plugin "google" {
  enabled = true
  version = "0.30.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}
```

## 5.3 Validation Flow Diagram

```mermaid
flowchart LR
    CODE["Terraform Code"]

    subgraph "Gate 1: Terragrunt Validation"
        TG_VAL["terragrunt run-all validate<br/>--filter-affected"]
    end

    subgraph "Gate 2: Linting"
        TFLINT["TFLint<br/>+ provider plugins"]
    end

    subgraph "Gate 3: Security"
        TRIVY["Trivy<br/>HIGH + CRITICAL"]
    end

    subgraph "Gate 4: Compliance"
        CHECKOV["Checkov<br/>CIS + custom policies"]
    end

    subgraph "Gate 5: Tests"
        TG_TEST["terragrunt run-all test"]
    end

    PASS{All pass?}
    PLAN["terragrunt run-all plan<br/>--filter-affected"]
    BLOCK["❌ Block"]

    CODE --> TG_VAL --> TFLINT --> TRIVY --> CHECKOV --> TG_TEST --> PASS
    PASS -->|Yes| PLAN
    PASS -->|No| BLOCK
```

---

# 6. Test Suite and Validation Report

## 6.1 Infrastructure Test Matrix

| ID | Test | Command / method | Expected result |
|---|---|---|---|
| I01 | Cluster accessible | `kubectl cluster-info` | API server responds |
| I02 | Nodes available | `kubectl get nodes` | Nodes `Ready` in all pools |
| I03 | Namespaces created | `kubectl get ns` | Per-stage namespaces present |
| I04 | CoreDNS operational | `kubectl -n kube-system get pods` | Pods `Running` |
| I05 | State backend | Verify storage backend | Remote state accessible |
| I06 | DNS zone configured | Cloud provider CLI | Zone active |
| I07 | Networking | Verify VNet/VPC and subnets | Resources created |
| I08 | Identity | Verify associated identity | Configured |
| I09 | RBAC | `kubectl auth can-i` per namespace | Correct permissions |
| I10 | NetworkPolicies | `kubectl get networkpolicies -A` | Policies applied |
| I11 | ResourceQuotas | `kubectl get resourcequotas -A` | Quotas configured |
| I12 | Terraform Tests | `terragrunt run-all test` | All tests pass |
| I13 | TFLint | `tflint --recursive` | No errors |
| I14 | Trivy | `trivy config` | No HIGH/CRITICAL |
| I15 | Checkov | `checkov -d iac/` | No critical failures |
| I16 | Idempotency | `terragrunt run-all plan` (re-run) | No pending changes |

## 6.2 Native Terraform Tests

```hcl
# modules/azure/cluster/tests/cluster_test.tftest.hcl

variables {
  cluster_name       = "test-cluster"
  region             = "westeurope"
  kubernetes_version = "1.29"
  environment        = "dev"
  node_count_system  = 2
  node_count_workloads = 2
  machine_type       = "Standard_D2s_v3"
}

run "cluster_creates_successfully" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.main.name == "test-cluster"
    error_message = "Cluster name does not match"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.main.location == "westeurope"
    error_message = "Region does not match"
  }
}

run "node_pools_configured" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.system.node_count == 2
    error_message = "System node count incorrect"
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.workloads.node_count == 2
    error_message = "Workload node count incorrect"
  }
}
```

## 6.3 Test Execution via Terragrunt

```hcl
# root terragrunt.hcl
terraform {
  after_hook "run_tests" {
    commands = ["apply"]
    execute  = ["terraform", "test"]
  }

  before_hook "validate" {
    commands = ["plan", "apply"]
    execute  = ["terraform", "validate"]
  }

  before_hook "lint" {
    commands = ["plan"]
    execute  = ["tflint", "--init"]
  }
}
```

Direct execution of all tests:

```bash
terragrunt run-all test
```

```mermaid
flowchart TB
    subgraph "Terragrunt Flow with Tests and Hooks"
        TG_INIT["terragrunt init"]
        HOOK_VAL["before_hook: terraform validate"]
        HOOK_LINT["before_hook: tflint"]
        TG_PLAN["terragrunt plan"]
        TG_APPLY["terragrunt apply"]
        HOOK_TEST["after_hook: terraform test<br/>/ terragrunt run-all test"]
        DONE["✅ Module validated"]

        TG_INIT --> HOOK_VAL --> HOOK_LINT --> TG_PLAN --> TG_APPLY --> HOOK_TEST --> DONE
    end
```

## 6.4 Minimum Evidence

- Output from `terragrunt run-all plan` and `terragrunt run-all apply`
- TFLint, Trivy, Checkov results
- `terragrunt run-all test` results
- `kubectl cluster-info` and `kubectl get nodes`
- `kubectl get ns`
- `kubectl get networkpolicies -A` and `kubectl get resourcequotas -A`
- Observations and limitations found

## 6.5 Post-Apply Validation Flow Diagram

```mermaid
flowchart TB
    START["Start Validation"]

    subgraph "Cloud Infrastructure"
        T_CLUSTER["Cluster accessible?"]
        T_NODES["Nodes Ready?"]
        T_NET["Networking configured?"]
        T_DNS["DNS zone active?"]
        T_ID["Identity configured?"]
    end

    subgraph "K8s Configuration"
        T_NS["Namespaces created?"]
        T_RBAC["RBAC configured?"]
        T_NP["NetworkPolicies applied?"]
        T_RQ["ResourceQuotas configured?"]
    end

    subgraph "IaC Quality"
        T_TFLINT["TFLint clean?"]
        T_TRIVY["Trivy no HIGH/CRITICAL?"]
        T_CHECKOV["Checkov no failures?"]
        T_TESTS["terragrunt run-all test passes?"]
        T_IDEM["Idempotent? (re-plan no changes)"]
    end

    PASS["✅ VALIDATION SUCCESSFUL"]
    FAIL["❌ FAILURE — Diagnose"]

    START --> T_CLUSTER
    T_CLUSTER -->|Yes| T_NODES -->|Yes| T_NET -->|Yes| T_DNS -->|Yes| T_ID
    T_ID -->|Yes| T_NS -->|Yes| T_RBAC -->|Yes| T_NP -->|Yes| T_RQ
    T_RQ -->|Yes| T_TFLINT -->|Yes| T_TRIVY -->|Yes| T_CHECKOV -->|Yes| T_TESTS
    T_TESTS -->|Yes| T_IDEM -->|Yes| PASS

    T_CLUSTER -->|No| FAIL
    T_NODES -->|No| FAIL
    T_NET -->|No| FAIL
    T_DNS -->|No| FAIL
    T_ID -->|No| FAIL
    T_NS -->|No| FAIL
    T_RBAC -->|No| FAIL
    T_NP -->|No| FAIL
    T_RQ -->|No| FAIL
    T_TFLINT -->|No| FAIL
    T_TRIVY -->|No| FAIL
    T_CHECKOV -->|No| FAIL
    T_TESTS -->|No| FAIL
    T_IDEM -->|No| FAIL
```

---

# 7. Common Multi-Cloud Contract

```hcl
variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster"
}

variable "region" {
  type        = string
  description = "Cloud region for the cluster"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "node_count_system" {
  type        = number
  description = "Number of nodes in system pool"
}

variable "node_count_workloads" {
  type        = number
  description = "Number of nodes in workloads pool"
}

variable "machine_type" {
  type        = string
  description = "VM size / machine type"
}
```

The variable contract is identical for all providers. Implementation differences are encapsulated within each cloud-specific module.

---

# 8. Scope and Limitations Alignment

| In scope | How it's covered |
|---|---|
| Multi-cloud IaC automation | Terraform + Terragrunt with per-provider modules |
| CI/CD pipeline | GitHub Actions with `--filter-affected` |
| Code validation | TFLint, Trivy, Checkov integrated |
| Infrastructure tests | `terragrunt run-all test` + kubectl validations |
| Runbook | Documented in phases A/B/C |
| Multi-cloud | Common contract with encapsulated per-provider modules |

| Out of scope | Treatment |
|---|---|
| Application deployment | Not included — responsibility of another team/phase |
| Platform tools (Argo CD, ingress, etc.) | Not included |
| Day-2 operations | Provisioning and initial validation only |
| Exhaustive hardening | Minimum for demo/validation |

---

# 9. Final Recommendation

1. **Terraform + Terragrunt** is the primary toolchain for multi-cloud infrastructure provisioning
2. **OpenTofu** is a valid alternative if open-source license is required
3. **Pulumi** complements for internal Kubernetes resources
4. **GitHub Actions** executes the pipeline with `--filter-affected` for optimized execution
5. **TFLint + Trivy + Checkov** form the quality and security gate
6. **terragrunt run-all test** + `kubectl` validations ensure post-apply correctness

### Responsibility Pattern

| Domain | Tool |
|---|---|
| Cloud provisioning | Terraform + Terragrunt |
| In-cluster resources | Pulumi (alternative) |
| Code validation | TFLint + Trivy + Checkov |
| CI/CD pipeline | GitHub Actions |
| Infrastructure tests | terragrunt run-all test |
| Post-apply validation | kubectl + smoke tests |

---

## NOTICE

This work is licensed under the [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/legalcode).

* SPDX-License-Identifier: CC-BY-4.0
* SPDX-FileCopyrightText: 2026 Contributors to the Eclipse Foundation
* Source URL: <https://github.com/eclipse-tractusx/tractus-x-umbrella>
