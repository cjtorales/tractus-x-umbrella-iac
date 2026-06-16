# Infrastructure Architecture, Cluster Components and Detailed Diagrams

<!-- TOC -->
* [1. Document Purpose](#1-document-purpose)
* [2. Global Architecture Overview](#2-global-architecture-overview)
  * [2.1 High-Level Context Diagram](#21-high-level-context-diagram)
  * [2.2 Actors and External Systems](#22-actors-and-external-systems)
* [3. End-to-End IaC Provisioning Architecture](#3-end-to-end-iac-provisioning-architecture)
  * [3.1 Complete End-to-End Diagram](#31-complete-end-to-end-diagram)
  * [3.2 Detailed Flow by Phases](#32-detailed-flow-by-phases)
* [4. Internal Cluster Architecture](#4-internal-cluster-architecture)
  * [4.1 Target Cluster Diagram](#41-target-cluster-diagram)
  * [4.2 Node Pools and Workload Distribution](#42-node-pools-and-workload-distribution)
  * [4.3 Cluster Design Decisions](#43-cluster-design-decisions)
* [5. Multi-Cluster Design and Stage Separation](#5-multi-cluster-design-and-stage-separation)
  * [5.1 Multi-Cluster per Stage Diagram](#51-multi-cluster-per-stage-diagram)
  * [5.2 Single Cluster with Namespaces Diagram](#52-single-cluster-with-namespaces-diagram)
  * [5.3 Hybrid Approach Diagram](#53-hybrid-approach-diagram)
  * [5.4 Namespace Isolation: RBAC, NetworkPolicies, ResourceQuotas](#54-namespace-isolation-rbac-networkpolicies-resourcequotas)
* [6. Network Architecture](#6-network-architecture)
  * [6.1 Detailed Network Diagram](#61-detailed-network-diagram)
  * [6.2 Network Traffic Flow](#62-network-traffic-flow)
* [7. Identity and Security Architecture](#7-identity-and-security-architecture)
  * [7.1 Identity Diagram per Cloud](#71-identity-diagram-per-cloud)
* [8. Terraform + Terragrunt Module Architecture](#8-terraform--terragrunt-module-architecture)
  * [8.1 Module and Dependencies Diagram](#81-module-and-dependencies-diagram)
  * [8.2 Complete Project Structure](#82-complete-project-structure)
  * [8.3 Terragrunt DRY Flow Diagram](#83-terragrunt-dry-flow-diagram)
* [9. GitHub Actions Pipeline — Detailed Diagram](#9-github-actions-pipeline--detailed-diagram)
  * [9.1 Complete Pipeline Diagram](#91-complete-pipeline-diagram)
  * [9.2 Optimized Execution Diagram](#92-optimized-execution-diagram)
  * [9.3 Pipeline Sequence Diagram](#93-pipeline-sequence-diagram)
* [10. IaC Validation Pipeline: TFLint, Trivy, Checkov](#10-iac-validation-pipeline-tflint-trivy-checkov)
  * [10.1 Validation Flow Diagram](#101-validation-flow-diagram)
* [11. State and Persistence Architecture](#11-state-and-persistence-architecture)
  * [11.1 State Management Diagram](#111-state-management-diagram)
* [12. Cloud-Agnostic Architecture: AKS vs GKE vs EKS](#12-cloud-agnostic-architecture-aks-vs-gke-vs-eks)
  * [12.1 Comparative Layer Diagram](#121-comparative-layer-diagram)
  * [12.2 Portability Matrix](#122-portability-matrix)
* [13. Pulumi for In-Cluster Resources — Diagram](#13-pulumi-for-in-cluster-resources--diagram)
* [14. Terraform Test Architecture](#14-terraform-test-architecture)
  * [14.1 Test Flow Diagram](#141-test-flow-diagram)
* [15. UML Deployment Diagram](#15-uml-deployment-diagram)
* [16. Main Flow Guides](#16-main-flow-guides)
  * [16.1 Flow: New Cluster from Scratch](#161-flow-new-cluster-from-scratch)
  * [16.2 Flow: Change in an Existing Module](#162-flow-change-in-an-existing-module)
  * [16.3 Flow: Add New Environment](#163-flow-add-new-environment)
* [17. References](#17-references)
* [NOTICE](#notice)
<!-- TOC -->

---

## Metadata

* **Date:** 2026
* **Dependencies:** Kubernetes (AKS/GKE/EKS), Terraform, Terragrunt, OpenTofu (alternative), Pulumi (in-cluster resources)
* **Target group:** Platform architecture, DevOps, Infrastructure engineering
* **CI/CD:** GitHub Actions
* **IaC Validation:** TFLint, Trivy, Checkov

---

# 1. Document Purpose

Complete the architecture documentation with detailed diagrams of all components, flows, project structures and operational guides. This document covers:

- Global multi-cloud infrastructure provisioning architecture
- Internal cluster architecture and multi-cluster/multi-stage design
- Network, identity and security
- Terraform + Terragrunt modules with dependencies
- GitHub Actions pipeline with optimized execution via `--filter-affected`
- Validation pipeline with TFLint, Trivy and Checkov
- Terraform tests via Terragrunt
- Main operational flow guides

---

# 2. Global Architecture Overview

## 2.1 High-Level Context Diagram

```mermaid
C4Context
    title Context Diagram — IaC Multi-Cloud

    Person(dev, "Dev / Operator", "Executes IaC and validates infrastructure")
    Person(reviewer, "Reviewer / Approver", "Reviews plans and approves applies")

    System(iac_platform, "IaC Platform", "Terraform + Terragrunt + GitHub Actions")

    System_Ext(git, "GitHub", "IaC code + workflows")
    System_Ext(azure, "Azure", "AKS, VNet, DNS, Identity")
    System_Ext(gcp, "GCP", "GKE, VPC, DNS, WI")
    System_Ext(aws, "AWS", "EKS, VPC, Route53, IAM")
    System_Ext(state, "Remote State", "Azure Blob / GCS / S3")

    Rel(dev, iac_platform, "Push code, review plans")
    Rel(reviewer, iac_platform, "Approve applies")
    Rel(iac_platform, git, "Read code and workflows")
    Rel(iac_platform, azure, "Provision infra")
    Rel(iac_platform, gcp, "Provision infra")
    Rel(iac_platform, aws, "Provision infra")
    Rel(iac_platform, state, "Read/write state")
```

## 2.2 Actors and External Systems

| Actor / System | Role | Interaction |
|---|---|---|
| Dev / Operator | Develops IaC, reviews plans, validates | Push code, `terragrunt plan`, validation |
| Reviewer / Approver | Reviews plans, approves applies | GitHub PR review, environment approval |
| GitHub | Repository + GitHub Actions | Trigger pipelines, store code |
| Azure / GCP / AWS | Cloud providers | Clusters, networking, DNS, identity |
| Remote State | State backend | Terraform state with locking |

---

# 3. End-to-End IaC Provisioning Architecture

## 3.1 Complete End-to-End Diagram

```mermaid
flowchart TB
    subgraph "SOURCE CODE"
        GIT["GitHub Repository<br/>━━━━━━━━━━<br/>iac/modules/ — Terraform modules<br/>iac/live/ — Terragrunt configs<br/>.github/workflows/ — Pipelines"]
    end

    subgraph "GITHUB ACTIONS PIPELINE"
        DETECT["Detect affected modules<br/>(terragrunt --filter-affected)"]
        VALIDATE["Validation via Terragrunt<br/>━━━━━━━━━━<br/>terragrunt run-all validate<br/>TFLint · Trivy · Checkov"]
        TEST_PRE["Tests<br/>━━━━━━━━━━<br/>terragrunt run-all test"]
        PLAN["Plan<br/>━━━━━━━━━━<br/>terragrunt run-all plan<br/>--filter-affected"]
        APPLY["Apply<br/>━━━━━━━━━━<br/>terragrunt run-all apply<br/>(PR approved on main)"]
        TEST_POST["Post-Apply<br/>━━━━━━━━━━<br/>terragrunt run-all test<br/>kubectl validations"]

        GIT --> DETECT
        DETECT --> VALIDATE
        VALIDATE --> TEST_PRE
        TEST_PRE --> PLAN
        PLAN --> APPLY
        APPLY --> TEST_POST
    end

    subgraph "CLOUD PROVIDERS"
        subgraph "Azure"
            AKS["AKS Cluster"]
            AZ_NET["VNet + Subnets + NSG"]
            AZ_DNS["Azure DNS"]
            AZ_ID["Managed Identity"]
            AZ_STATE["Azure Blob (state)"]
        end
        subgraph "GCP"
            GKE["GKE Cluster"]
            GCP_NET["VPC + Subnets + FW"]
            GCP_DNS["Cloud DNS"]
            GCP_ID["Workload Identity"]
            GCP_STATE["GCS (state)"]
        end
        subgraph "AWS"
            EKS["EKS Cluster"]
            AWS_NET["VPC + Subnets + SG"]
            AWS_DNS["Route53"]
            AWS_ID["IAM Roles / IRSA"]
            AWS_STATE["S3 (state)"]
        end

        APPLY --> AKS
        APPLY --> GKE
        APPLY --> EKS
    end

    subgraph "POST-PROVISIONING (Optional)"
        PULUMI["Pulumi<br/>━━━━━━━━━━<br/>Namespaces · RBAC<br/>NetworkPolicies · ResourceQuotas"]

        AKS --> PULUMI
        GKE --> PULUMI
        EKS --> PULUMI
    end
```

## 3.2 Detailed Flow by Phases

```mermaid
flowchart LR
    subgraph "Day 0 — Setup"
        P1["1. Create remote<br/>state backend"]
        P2["2. Configure<br/>service principal"]
        P3["3. Configure<br/>GitHub secrets"]

        P1 --> P2 --> P3
    end

    subgraph "Day 0 — Provisioning"
        P4["4. Push code<br/>to main"]
        P5["5. CI validates via Terragrunt<br/>TFLint+Trivy+Checkov"]
        P5B["6. terragrunt run-all test"]
        P6["7. terragrunt plan<br/>--filter-affected"]
        P7["8. PR approved"]
        P8["9. terragrunt apply<br/>--filter-affected"]

        P4 --> P5 --> P5B --> P6 --> P7 --> P8
    end

    subgraph "Day 0 — Base Config"
        P9["10. Namespaces +<br/>RBAC + Policies"]
        P10["11. terragrunt<br/>run-all test"]
        P11["12. kubectl<br/>validations"]

        P9 --> P10 --> P11
    end

    P3 --> P4
    P8 --> P9
```

---

# 4. Internal Cluster Architecture

## 4.1 Target Cluster Diagram

```mermaid
flowchart TB
    subgraph "MANAGED CONTROL PLANE"
        CP["API Server · Scheduler<br/>Controllers · etcd<br/>━━━━━━━━━━<br/>Managed by cloud provider"]
    end

    subgraph "NODE POOL: SYSTEM"
        direction TB
        KUBESYS["kube-system<br/>━━━━━━━━━━<br/>CoreDNS · CNI<br/>kube-proxy · metrics-server"]
    end

    subgraph "NODE POOL: WORKLOADS"
        direction TB
        NS_DEV["namespace: dev<br/>━━━━━━━━━━<br/>ResourceQuota: to estimate per application<br/>NetworkPolicy: to define per application<br/>RBAC: to estimate per application"]
        NS_STG["namespace: staging<br/>━━━━━━━━━━<br/>ResourceQuota: to estimate per application<br/>NetworkPolicy: to define per application<br/>RBAC: to estimate per application"]
        NS_PROD["namespace: prod<br/>━━━━━━━━━━<br/>ResourceQuota: to estimate per application<br/>NetworkPolicy: to define per application<br/>RBAC: to estimate per application"]
    end

    STORAGE["💾 StorageClass<br/>cloud provider default"]

    CP --> KUBESYS
    CP --> NS_DEV
    CP --> NS_STG
    CP --> NS_PROD
    NS_DEV --> STORAGE
    NS_STG --> STORAGE
    NS_PROD --> STORAGE
```

## 4.2 Node Pools and Workload Distribution

```mermaid
flowchart LR
    subgraph "Node Pool: System"
        NP_SYS["VM: to estimate per application<br/>Nodes: to estimate per application<br/>Taints: platform=true:NoSchedule"]

        SYS_CORE["CoreDNS<br/>kube-proxy<br/>metrics-server"]

        NP_SYS --> SYS_CORE
    end

    subgraph "Node Pool: Workloads"
        NP_WRK["VM: to estimate per application<br/>Nodes: to estimate per application<br/>Cluster Autoscaler enabled<br/>Labels: workload=app"]

        WRK_DEV["Pods: dev"]
        WRK_STG["Pods: staging"]
        WRK_PROD["Pods: prod"]

        NP_WRK --> WRK_DEV
        NP_WRK --> WRK_STG
        NP_WRK --> WRK_PROD
    end
```

## 4.3 Cluster Design Decisions

| # | Decision | Justification |
|---|----------|---------------|
| 1 | **Managed cluster** | AKS/GKE/EKS — control plane managed by cloud |
| 2 | **Two node pools** | Separate system components from business workloads |
| 3 | **Namespaces per stage** | Logical dev/staging/prod separation with RBAC and policies |
| 4 | **NetworkPolicies** | Network isolation between namespaces (to define per application) |
| 5 | **ResourceQuotas** | Prevent one stage from consuming all resources (to estimate per application) |
| 6 | **Autoscaling** | Workloads node pool with Cluster Autoscaler enabled |

---

# 5. Multi-Cluster Design and Stage Separation

## 5.1 Multi-Cluster per Stage Diagram

```mermaid
flowchart TB
    TG["Terragrunt"]

    subgraph "Cluster DEV"
        DEV_C["AKS/GKE/EKS<br/>Nodes: to estimate per application<br/>Cluster Autoscaler enabled"]
        DEV_NS["ns: app-dev · ns: platform"]
        DEV_C --> DEV_NS
    end

    subgraph "Cluster STAGING"
        STG_C["AKS/GKE/EKS<br/>Nodes: to estimate per application<br/>Cluster Autoscaler enabled"]
        STG_NS["ns: app-staging · ns: platform"]
        STG_C --> STG_NS
    end

    subgraph "Cluster PROD"
        PROD_C["AKS/GKE/EKS<br/>Nodes: to estimate per application<br/>Cluster Autoscaler enabled"]
        PROD_NS["ns: app-prod · ns: platform"]
        PROD_C --> PROD_NS
    end

    TG --> DEV_C
    TG --> STG_C
    TG --> PROD_C
```

## 5.2 Single Cluster with Namespaces Diagram

```mermaid
flowchart TB
    TG["Terragrunt"]

    subgraph "Shared Cluster"
        CLUSTER["AKS/GKE/EKS<br/>Node pools with labels/taints<br/>Cluster Autoscaler enabled"]

        NS_DEV["ns: dev<br/>Quota: to estimate · Policy: to define"]
        NS_STG["ns: staging<br/>Quota: to estimate · Policy: to define"]
        NS_PROD["ns: prod<br/>Quota: to estimate · Policy: to define"]
        NS_PLAT["ns: platform<br/>Shared components"]

        CLUSTER --> NS_DEV
        CLUSTER --> NS_STG
        CLUSTER --> NS_PROD
        CLUSTER --> NS_PLAT
    end

    TG --> CLUSTER
```

## 5.3 Hybrid Approach Diagram

```mermaid
flowchart TB
    TG["Terragrunt<br/>━━━━━━━━━━<br/>Orchestrates both clusters"]

    subgraph "Shared Cluster (dev + staging)"
        SHARED["Shared Cluster<br/>━━━━━━━━━━<br/>Optimized cost<br/>Shared upgrades"]
        S_DEV["ns: dev<br/>Quota: to estimate<br/>NetworkPolicy: to define"]
        S_STG["ns: staging<br/>Quota: to estimate<br/>NetworkPolicy: to define"]
        S_PLAT["ns: platform"]

        SHARED --> S_DEV
        SHARED --> S_STG
        SHARED --> S_PLAT
    end

    subgraph "Production Cluster (separate)"
        PROD["Prod Cluster<br/>━━━━━━━━━━<br/>Total isolation<br/>Independent upgrades"]
        P_PROD["ns: prod<br/>Quota: to estimate<br/>NetworkPolicy: to define"]
        P_PLAT["ns: platform"]

        PROD --> P_PROD
        PROD --> P_PLAT
    end

    TG --> SHARED
    TG --> PROD
```

## 5.4 Namespace Isolation: RBAC, NetworkPolicies, ResourceQuotas

```mermaid
flowchart TB
    subgraph "Namespace: dev"
        RBAC_DEV["RBAC<br/>━━━━━━━━━━<br/>Role: to estimate per application<br/>RoleBinding: to estimate per application<br/>Permissions: to define per application"]
        NP_DEV["NetworkPolicy<br/>━━━━━━━━━━<br/>To define per application<br/>E.g.: default-deny + allow-same-ns"]
        RQ_DEV["ResourceQuota<br/>━━━━━━━━━━<br/>To estimate per application<br/>requests.cpu / memory<br/>limits.cpu / memory<br/>pods"]
    end

    subgraph "Namespace: prod"
        RBAC_PROD["RBAC<br/>━━━━━━━━━━<br/>Role: to estimate per application<br/>RoleBinding: to estimate per application<br/>Permissions: to define per application"]
        NP_PROD["NetworkPolicy<br/>━━━━━━━━━━<br/>To define per application<br/>E.g.: deny-all + specific ingress"]
        RQ_PROD["ResourceQuota<br/>━━━━━━━━━━<br/>To estimate per application<br/>requests.cpu / memory<br/>limits.cpu / memory<br/>pods"]
    end
```

---

# 6. Network Architecture

## 6.1 Detailed Network Diagram

```mermaid
flowchart TB
    subgraph "Cloud Provider"
        subgraph "VNet / VPC"
            SUBNET_NODES["Subnet: cluster-nodes"]
            SUBNET_PODS["Subnet: pods<br/>(if applicable, e.g. GKE VPC-native)"]
            SUBNET_SVC["Subnet: services"]
        end

        NSG["NSG / Security Group / FW Rules<br/>━━━━━━━━━━<br/>Inbound: 443 (API server)<br/>Outbound: cluster egress"]

        NAT["NAT Gateway<br/>(egress traffic)"]
    end

    subgraph "Kubernetes Cluster"
        CP["Control Plane<br/>(managed, separate VNet/VPC)"]
        NODES_SYS["Node Pool: system<br/>Subnet: cluster-nodes"]
        NODES_WRK["Node Pool: workloads<br/>Subnet: cluster-nodes"]
    end

    SUBNET_NODES --> NODES_SYS
    SUBNET_NODES --> NODES_WRK
    CP --> NODES_SYS
    CP --> NODES_WRK
    NSG --> SUBNET_NODES
    NODES_WRK --> NAT
```

## 6.2 Network Traffic Flow

```mermaid
sequenceDiagram
    participant Req as Request
    participant API as K8s API Server
    participant Node as Worker Node
    participant Pod as Pod

    Note over Req, API: Cluster access
    Req->>API: kubectl (HTTPS 443)
    API->>Node: Schedule pod
    Node->>Pod: Start container

    Note over Pod, Node: Egress
    Pod->>Node: External request
    Node->>Node: NAT Gateway
    Note right of Node: Internet / other services
```

---

# 7. Identity and Security Architecture

## 7.1 Identity Diagram per Cloud

```mermaid
flowchart TB
    subgraph "Azure"
        AZ_SP["Service Principal<br/>(CI/CD — GitHub Actions)"]
        AZ_MI["Managed Identity<br/>(Cluster)"]
        AZ_RBAC["Azure RBAC<br/>Contributor on Resource Group"]

        AZ_SP --> AZ_RBAC
        AZ_MI --> AZ_RBAC
    end

    subgraph "GCP"
        GCP_SA["Service Account<br/>(CI/CD — GitHub Actions)"]
        GCP_WI["Workload Identity<br/>(Cluster)"]
        GCP_IAM["IAM Roles<br/>container.admin"]

        GCP_SA --> GCP_IAM
        GCP_WI --> GCP_IAM
    end

    subgraph "AWS"
        AWS_USER["IAM User / Role<br/>(CI/CD — GitHub Actions)"]
        AWS_IRSA["IRSA<br/>(Cluster pods)"]
        AWS_POLICY["IAM Policies<br/>EKS full access"]

        AWS_USER --> AWS_POLICY
        AWS_IRSA --> AWS_POLICY
    end
```

---

# 8. Terraform + Terragrunt Module Architecture

## 8.1 Module and Dependencies Diagram

```mermaid
graph TB
    subgraph "Root Modules (Terragrunt)"
        ROOT_AZ["live/azure/dev/<br/>terragrunt.hcl"]
        ROOT_GCP["live/gcp/dev/<br/>terragrunt.hcl"]
        ROOT_AWS["live/aws/dev/<br/>terragrunt.hcl"]
    end

    subgraph "Azure Modules"
        MOD_NET_AZ["modules/azure/networking/<br/>━━━━━━━━━━<br/>Inputs: region, cidr_block, environment<br/>Outputs: vpc_id, subnet_ids, nsg_id"]
        MOD_AKS["modules/azure/cluster/<br/>━━━━━━━━━━<br/>Inputs: cluster_name, region,<br/>  k8s_version, node_count, vm_size<br/>Outputs: endpoint, ca, kubeconfig"]
        MOD_DNS_AZ["modules/azure/dns/"]
        MOD_ID_AZ["modules/azure/identity/"]
    end

    subgraph "GCP Modules"
        MOD_NET_GCP["modules/gcp/networking/"]
        MOD_GKE["modules/gcp/cluster/"]
        MOD_DNS_GCP["modules/gcp/dns/"]
        MOD_ID_GCP["modules/gcp/identity/"]
    end

    subgraph "AWS Modules"
        MOD_NET_AWS["modules/aws/networking/"]
        MOD_EKS["modules/aws/cluster/"]
        MOD_DNS_AWS["modules/aws/dns/"]
        MOD_ID_AWS["modules/aws/identity/"]
    end

    ROOT_AZ --> MOD_NET_AZ
    ROOT_AZ --> MOD_AKS
    ROOT_AZ --> MOD_DNS_AZ
    ROOT_AZ --> MOD_ID_AZ

    ROOT_GCP --> MOD_NET_GCP
    ROOT_GCP --> MOD_GKE
    ROOT_GCP --> MOD_DNS_GCP
    ROOT_GCP --> MOD_ID_GCP

    ROOT_AWS --> MOD_NET_AWS
    ROOT_AWS --> MOD_EKS
    ROOT_AWS --> MOD_DNS_AWS
    ROOT_AWS --> MOD_ID_AWS

    MOD_NET_AZ -->|"vpc_id, subnet_ids"| MOD_AKS
    MOD_NET_GCP -->|"vpc_id, subnet_ids"| MOD_GKE
    MOD_NET_AWS -->|"vpc_id, subnet_ids"| MOD_EKS
    MOD_ID_AZ -->|"identity_id"| MOD_AKS
    MOD_ID_GCP -->|"service_account"| MOD_GKE
    MOD_ID_AWS -->|"role_arn"| MOD_EKS
```

## 8.2 Complete Project Structure

```text
repo/
├── iac/
│   ├── modules/
│   │   ├── azure/
│   │   │   ├── cluster/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   ├── outputs.tf
│   │   │   │   ├── versions.tf
│   │   │   │   └── tests/
│   │   │   │       └── cluster_test.tftest.hcl
│   │   │   ├── networking/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── outputs.tf
│   │   │   ├── dns/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── outputs.tf
│   │   │   ├── identity/
│   │   │   │   ├── main.tf
│   │   │   │   ├── variables.tf
│   │   │   │   └── outputs.tf
│   │   │   └── remote-state/
│   │   │       ├── main.tf
│   │   │       ├── variables.tf
│   │   │       └── outputs.tf
│   │   ├── gcp/
│   │   │   ├── cluster/
│   │   │   │   └── ... (same structure)
│   │   │   ├── networking/
│   │   │   ├── dns/
│   │   │   ├── identity/
│   │   │   └── remote-state/
│   │   ├── aws/
│   │   │   ├── cluster/
│   │   │   │   └── ... (same structure)
│   │   │   ├── networking/
│   │   │   ├── dns/
│   │   │   ├── identity/
│   │   │   └── remote-state/
│   │   └── pulumi/                          # (Optional) In-cluster resources
│   │       ├── Pulumi.yaml
│   │       ├── Pulumi.dev.yaml
│   │       ├── Pulumi.prod.yaml
│   │       └── index.ts
│   ├── live/
│   │   ├── terragrunt.hcl              # Root config (DRY)
│   │   ├── azure/
│   │   │   ├── dev/
│   │   │   │   ├── networking/terragrunt.hcl
│   │   │   │   ├── cluster/terragrunt.hcl
│   │   │   │   └── env.hcl
│   │   │   ├── staging/
│   │   │   │   └── ...
│   │   │   └── prod/
│   │   │       └── ...
│   │   ├── gcp/
│   │   │   └── ...
│   │   └── aws/
│   │       └── ...
│   └── .tflint.hcl
├── .github/
│   └── workflows/
│       ├── iac-validate.yml
│       ├── iac-plan.yml
│       └── iac-apply.yml
└── docs/
```

## 8.3 Terragrunt DRY Flow Diagram

```mermaid
flowchart TB
    subgraph "Root terragrunt.hcl"
        ROOT["iac/live/terragrunt.hcl<br/>━━━━━━━━━━<br/>remote_state { ... }<br/>generate provider { ... }<br/>inputs = merge(<br/>  read_terragrunt_config(env.hcl),<br/>  { common vars }<br/>)"]
    end

    subgraph "Environment Config"
        ENV_DEV["azure/dev/env.hcl<br/>━━━━━━━━━━<br/>environment = dev<br/>region = westeurope<br/>node_count = to estimate"]
        ENV_PROD["azure/prod/env.hcl<br/>━━━━━━━━━━<br/>environment = prod<br/>region = westeurope<br/>node_count = to estimate"]
    end

    subgraph "Module Configs (inherit root)"
        MOD_NET_DEV["azure/dev/networking/<br/>terragrunt.hcl<br/>━━━━━━━━━━<br/>source = modules/azure/networking<br/>dependencies = []"]
        MOD_CL_DEV["azure/dev/cluster/<br/>terragrunt.hcl<br/>━━━━━━━━━━<br/>source = modules/azure/cluster<br/>dependencies = [networking]"]
    end

    ROOT --> ENV_DEV
    ROOT --> ENV_PROD
    ENV_DEV --> MOD_NET_DEV
    ENV_DEV --> MOD_CL_DEV
    MOD_NET_DEV -->|"dependency"| MOD_CL_DEV
```

---

# 9. GitHub Actions Pipeline — Detailed Diagram

## 9.1 Complete Pipeline Diagram

```mermaid
flowchart TB
    subgraph "Trigger"
        PR["Pull Request → iac/**"]
        PUSH["Push main → iac/**"]
    end

    subgraph "Job 1: Validation via Terragrunt"
        TG_VAL["terragrunt run-all validate<br/>--filter-affected"]
        LINT["TFLint<br/>(with plugins: azurerm, google, aws)"]
        TRIVY_S["Trivy config scan<br/>(HIGH + CRITICAL)"]
        CHECKOV_S["Checkov<br/>(terraform framework)"]

        TG_VAL --> LINT --> TRIVY_S --> CHECKOV_S
    end

    subgraph "Job 2: Tests"
        TG_TEST["terragrunt run-all test<br/>--filter-affected"]
    end

    subgraph "Job 3: Plan"
        TG_PLAN["terragrunt run-all plan<br/>--filter-affected"]
        COMMENT["PR comment with plan diff"]
    end

    subgraph "Job 4: Apply (PR approved on main)"
        TG_APPLY["terragrunt run-all apply<br/>--filter-affected"]
    end

    subgraph "Job 5: Post-Apply"
        TG_TEST_POST["terragrunt run-all test"]
        K8S_VAL["kubectl cluster-info<br/>kubectl get nodes<br/>kubectl get ns"]
        REPORT["Generate report"]
    end

    PR --> TG_VAL
    PUSH --> TG_VAL
    CHECKOV_S --> TG_TEST
    TG_TEST --> TG_PLAN
    TG_PLAN --> COMMENT
    TG_PLAN --> TG_APPLY
    TG_APPLY --> TG_TEST_POST
    TG_TEST_POST --> K8S_VAL
    K8S_VAL --> REPORT
```

## 9.2 Optimized Execution Diagram

```mermaid
flowchart TB
    PUSH["Push to main"]
    FILTER["terragrunt run-all plan<br/>--filter-affected<br/>━━━━━━━━━━<br/>Filters modified, added or<br/>removed components between<br/>main and HEAD"]

    subgraph "Selective Execution"
        ONLY_MOD["Only affected modules<br/>+ their dependents"]
        SKIP["Unchanged modules<br/>are skipped"]
    end

    PUSH --> FILTER
    FILTER --> ONLY_MOD
    FILTER --> SKIP
```

## 9.3 Pipeline Sequence Diagram

```mermaid
sequenceDiagram
    actor Dev as Dev / Operator
    participant GH as GitHub
    participant GHA as GitHub Actions
    participant TG as Terragrunt
    participant Cloud as Cloud Provider
    participant K8s as Kubernetes

    Dev->>GH: Push to main (iac/ changes)
    GH->>GHA: Trigger workflow

    rect rgb(230, 245, 255)
        Note over GHA, TG: Validation via Terragrunt
        GHA->>TG: terragrunt run-all validate --filter-affected
        TG-->>GHA: OK / Errors
        GHA->>GHA: TFLint (affected modules)
        GHA->>GHA: Trivy scan
        GHA->>GHA: Checkov scan
        GHA->>TG: terragrunt run-all test --filter-affected
        TG-->>GHA: Test results
    end

    rect rgb(230, 255, 230)
        Note over TG, Cloud: Plan
        GHA->>TG: terragrunt run-all plan --filter-affected
        TG->>Cloud: API calls (read-only)
        Cloud-->>TG: Resource diff
        TG-->>GHA: Plan output
    end

    rect rgb(255, 245, 230)
        Note over Dev, Cloud: Apply (PR approved on main)
        Dev->>GH: Approve PR and merge
        GHA->>TG: terragrunt run-all apply --filter-affected
        TG->>Cloud: Create/Update resources
        Cloud-->>TG: Resources created
    end

    rect rgb(255, 230, 230)
        Note over GHA, K8s: Post-Apply Validation
        GHA->>K8s: kubectl cluster-info
        GHA->>K8s: kubectl get nodes
        K8s-->>GHA: Results
        GHA-->>Dev: Final report
    end
```

---

# 10. IaC Validation Pipeline: TFLint, Trivy, Checkov

## 10.1 Validation Flow Diagram

```mermaid
flowchart TB
    CODE["Terraform Code<br/>(push / PR)"]

    subgraph "Gate 1: Terragrunt Validation"
        TG_VAL["terragrunt run-all validate<br/>--filter-affected"]
    end

    subgraph "Gate 2: Linting — TFLint"
        TFLINT["TFLint<br/>━━━━━━━━━━<br/>General Terraform rules<br/>Plugin azurerm: Azure rules<br/>Plugin google: GCP rules<br/>Plugin aws: AWS rules"]
    end

    subgraph "Gate 3: Security — Trivy"
        TRIVY["Trivy config<br/>━━━━━━━━━━<br/>Detection of:<br/>· Disabled encryption<br/>· Unintended public access<br/>· Disabled logging<br/>· Obsolete versions"]
    end

    subgraph "Gate 4: Compliance — Checkov"
        CHECKOV["Checkov<br/>━━━━━━━━━━<br/>CIS Kubernetes Benchmark<br/>CIS Azure/GCP/AWS<br/>Custom policies<br/>+1000 built-in checks"]
    end

    subgraph "Gate 5: Tests"
        TG_TEST["terragrunt run-all test"]
    end

    PASS{All<br/>pass?}
    NEXT["✅ Continue to Plan"]
    BLOCK["❌ Block merge/apply"]

    CODE --> TG_VAL --> TFLINT --> TRIVY --> CHECKOV --> TG_TEST --> PASS
    PASS -->|Yes| NEXT
    PASS -->|No| BLOCK
```

---

# 11. State and Persistence Architecture

## 11.1 State Management Diagram

```mermaid
flowchart TB
    subgraph "Terraform State"
        TF_STATE["terraform.tfstate<br/>━━━━━━━━━━<br/>Complete inventory of<br/>provisioned resources"]
    end

    subgraph "Azure Backend"
        AZ_STORAGE["Azure Storage Account<br/>Container: tfstate<br/>Blob: {env}/{module}.tfstate<br/>Locking: Blob Lease"]
    end

    subgraph "GCP Backend"
        GCS_BUCKET["GCS Bucket<br/>Object: {env}/{module}.tfstate<br/>Locking: GCS Object Lock"]
    end

    subgraph "AWS Backend"
        S3_BUCKET["S3 Bucket<br/>Key: {env}/{module}.tfstate<br/>Locking: DynamoDB"]
    end

    TF_STATE --> AZ_STORAGE
    TF_STATE --> GCS_BUCKET
    TF_STATE --> S3_BUCKET

    subgraph "Terragrunt Auto-Config"
        TG_STATE["terragrunt.hcl<br/>━━━━━━━━━━<br/>remote_state {<br/>  backend = 'azurerm' / 'gcs' / 's3'<br/>  config = {<br/>    path = '${env}/${module}.tfstate'<br/>  }<br/>}"]
    end

    TG_STATE --> AZ_STORAGE
    TG_STATE --> GCS_BUCKET
    TG_STATE --> S3_BUCKET
```

---

# 12. Cloud-Agnostic Architecture: AKS vs GKE vs EKS

## 12.1 Comparative Layer Diagram

```mermaid
flowchart TB
    subgraph "PORTABLE LAYER (Identical)"
        L_TG["Terragrunt Config<br/>Same structure<br/>--filter-affected"]
        L_GHA["GitHub Actions<br/>Same pipeline"]
        L_TOOLS["TFLint · Trivy · Checkov<br/>Same validations"]
        L_TESTS["terragrunt run-all test<br/>Same pattern"]
        L_VARS["Variables Contract<br/>Same contract"]
    end

    subgraph "AZURE LAYER"
        AZ_MOD["module: azure/cluster<br/>provider: azurerm"]
        AZ_NET["VNet + Subnet + NSG"]
        AZ_DNS["Azure DNS"]
        AZ_ID["Managed Identity"]
        AZ_STATE["Azure Blob"]
    end

    subgraph "GCP LAYER"
        GCP_MOD["module: gcp/cluster<br/>provider: google"]
        GCP_NET["VPC + Subnet + FW"]
        GCP_DNS["Cloud DNS"]
        GCP_ID["Workload Identity"]
        GCP_STATE["GCS"]
    end

    subgraph "AWS LAYER"
        AWS_MOD["module: aws/cluster<br/>provider: aws"]
        AWS_NET["VPC + Subnet + SG"]
        AWS_DNS["Route53"]
        AWS_ID["IAM / IRSA"]
        AWS_STATE["S3 + DynamoDB"]
    end

    L_TG --> AZ_MOD
    L_TG --> GCP_MOD
    L_TG --> AWS_MOD
```

## 12.2 Portability Matrix

| Aspect | Azure (AKS) | GCP (GKE) | AWS (EKS) | Portability |
|---------|-------------|-----------|-----------|--------------|
| Cluster | `azurerm_kubernetes_cluster` | `google_container_cluster` | `aws_eks_cluster` | Different module, same contract |
| Networking | VNet + Subnet + NSG | VPC + Subnet + FW | VPC + Subnet + SG | Different module, same contract |
| DNS | Azure DNS | Cloud DNS | Route53 | Different module, same contract |
| Identity | Managed Identity | Workload Identity | IRSA | Different config |
| State backend | Azure Blob | GCS | S3 + DynamoDB | Terragrunt abstracts it |
| Node pools | AKS node pools | GKE node pools | EKS managed node groups | Different module |
| Terragrunt config | ✅ Identical | ✅ Identical | ✅ Identical | ✅ Portable |
| GitHub Actions | ✅ Identical | ✅ Identical | ✅ Identical | ✅ Portable |
| TFLint/Trivy/Checkov | ✅ Identical | ✅ Identical | ✅ Identical | ✅ Portable |

---

# 13. Pulumi for In-Cluster Resources — Diagram

```mermaid
flowchart TB
    subgraph "Terraform + Terragrunt (Cloud Infra)"
        TF_OUT["Cluster Outputs<br/>━━━━━━━━━━<br/>cluster_endpoint<br/>ca_certificate<br/>kubeconfig_path"]
    end

    subgraph "Pulumi (In-Cluster Resources)"
        PULUMI_PROG["Pulumi Program (TypeScript)<br/>━━━━━━━━━━<br/>import * as k8s from '@pulumi/kubernetes'<br/><br/>// Consume TF outputs<br/>const provider = new k8s.Provider('k8s', {<br/>  kubeconfig: tfOutputs.kubeconfig<br/>})"]

        subgraph "Created Resources"
            NS_DEV["Namespace: dev"]
            NS_STG["Namespace: staging"]
            NS_PROD["Namespace: prod"]
            RBAC["RBAC Roles + Bindings<br/>(to estimate per application)"]
            NP["NetworkPolicies<br/>(to define per application)"]
            RQ["ResourceQuotas<br/>(to estimate per application)"]
        end

        PULUMI_PROG --> NS_DEV
        PULUMI_PROG --> NS_STG
        PULUMI_PROG --> NS_PROD
        PULUMI_PROG --> RBAC
        PULUMI_PROG --> NP
        PULUMI_PROG --> RQ
    end

    TF_OUT -->|"kubeconfig"| PULUMI_PROG
```

---

# 14. Terraform Test Architecture

## 14.1 Test Flow Diagram

```mermaid
flowchart TB
    subgraph "Native Terraform Tests"
        TEST_FILE[".tftest.hcl files<br/>━━━━━━━━━━<br/>Located in modules/{provider}/cluster/tests/"]

        subgraph "Test Types"
            PLAN_TEST["Plan Tests<br/>━━━━━━━━━━<br/>command = plan<br/>Validates configuration<br/>without creating resources"]
            APPLY_TEST["Apply Tests (optional)<br/>━━━━━━━━━━<br/>command = apply<br/>Creates real resources<br/>and validates state"]
        end

        subgraph "Assertions"
            ASSERT1["assert: cluster name"]
            ASSERT2["assert: correct region"]
            ASSERT3["assert: node count"]
            ASSERT4["assert: K8s version"]
            ASSERT5["assert: outputs present"]
        end

        TEST_FILE --> PLAN_TEST
        TEST_FILE --> APPLY_TEST
        PLAN_TEST --> ASSERT1
        PLAN_TEST --> ASSERT2
        PLAN_TEST --> ASSERT3
        APPLY_TEST --> ASSERT4
        APPLY_TEST --> ASSERT5
    end

    subgraph "Execution"
        LOCAL["terraform test (local)"]
        CI["GitHub Actions (CI)"]
        TG_CMD["terragrunt run-all test"]
        TG_HOOK["Terragrunt after_hook"]
    end

    TEST_FILE --> LOCAL
    TEST_FILE --> CI
    TEST_FILE --> TG_CMD
    TEST_FILE --> TG_HOOK
```

---

# 15. UML Deployment Diagram

```mermaid
flowchart TB
    subgraph "Node: Dev / Operator Workstation"
        TF_CLI["Terraform / OpenTofu CLI"]
        TG_CLI["Terragrunt CLI"]
        KUBECTL["kubectl"]
        PULUMI_CLI["Pulumi CLI (optional)"]
    end

    subgraph "Node: GitHub"
        GH_REPO["Repository<br/>iac/ + .github/workflows/"]
        GH_ACTIONS["GitHub Actions Runners"]
    end

    subgraph "Node: Cloud Provider"
        subgraph "Kubernetes Cluster"
            subgraph "Control Plane"
                API["API Server"]
                ETCD["etcd"]
            end

            subgraph "Node Pool: System"
                CORE["CoreDNS · CNI<br/>kube-proxy"]
            end

            subgraph "Node Pool: Workloads"
                NS_D["ns: dev"]
                NS_S["ns: staging"]
                NS_P["ns: prod"]
            end
        end

        CLOUD_NET["VNet / VPC"]
        CLOUD_DNS["DNS Zone"]
        CLOUD_STATE["State Backend"]
        CLOUD_ID["Identity"]
    end

    TF_CLI --> API
    TG_CLI --> TF_CLI
    KUBECTL --> API
    GH_ACTIONS --> TG_CLI
    TG_CLI --> CLOUD_STATE
    GH_REPO --> GH_ACTIONS
```

---

# 16. Main Flow Guides

## 16.1 Flow: New Cluster from Scratch

```mermaid
flowchart TB
    A["1. Create remote backend<br/>(iac/modules/{provider}/remote-state)"]
    B["2. Configure service principal<br/>and GitHub secrets"]
    C["3. Create env.hcl for<br/>the new environment"]
    D["4. Create terragrunt.hcl<br/>for networking"]
    E["5. Create terragrunt.hcl<br/>for cluster"]
    F["6. Push to main"]
    G["7. GitHub Actions:<br/>validate → test → plan → apply"]
    H["8. terragrunt run-all test"]
    I["9. kubectl validations"]
    J["10. ✅ Cluster ready"]

    A --> B --> C --> D --> E --> F --> G --> H --> I --> J
```

## 16.2 Flow: Change in an Existing Module

```mermaid
flowchart TB
    A["1. Modify module<br/>(e.g.: modules/azure/cluster/)"]
    B["2. Update tests<br/>if needed"]
    C["3. Push to feature branch"]
    D["4. PR: validate + test + plan<br/>(automatic)"]
    E["5. Review plan diff"]
    F["6. Approve PR and merge to main"]
    G["7. GitHub Actions detects<br/>only affected modules<br/>(--filter-affected)"]
    H["8. Apply only environments<br/>using that module"]
    I["9. Post-apply tests"]
    J["10. ✅ Change applied"]

    A --> B --> C --> D --> E --> F --> G --> H --> I --> J
```

## 16.3 Flow: Add New Environment

```mermaid
flowchart TB
    A["1. Create folder<br/>live/{cloud}/{new-env}/"]
    B["2. Create env.hcl<br/>with environment variables"]
    C["3. Create terragrunt.hcl<br/>for each required module"]
    D["4. Modules are reused<br/>(DRY via Terragrunt)"]
    E["5. Push to main"]
    F["6. GitHub Actions:<br/>validate → test → plan → apply"]
    G["7. ✅ New environment ready"]

    A --> B --> C --> D --> E --> F --> G
```

---

# 17. References

### Technical References
- [Terraform — Official Documentation](https://developer.hashicorp.com/terraform/docs)
- [Terragrunt — Official Documentation](https://terragrunt.gruntwork.io/docs/)
- [Terragrunt --filter-affected](https://terragrunt.gruntwork.io/docs/reference/cli-options/#filter-affected)
- [OpenTofu — Official Documentation](https://opentofu.org/docs/)
- [Pulumi — Kubernetes Provider](https://www.pulumi.com/registry/packages/kubernetes/)
- [TFLint — GitHub Repository](https://github.com/terraform-linters/tflint)
- [Trivy — Official Documentation](https://aquasecurity.github.io/trivy/)
- [Checkov — Official Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [GitHub Actions — Official Documentation](https://docs.github.com/en/actions)
- [Microsoft Learn — AKS](https://learn.microsoft.com/en-us/azure/aks/)
- [Google Cloud — GKE](https://cloud.google.com/kubernetes-engine/docs/)
- [AWS — EKS](https://docs.aws.amazon.com/eks/)

---

## NOTICE

This work is licensed under the [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/legalcode).

* SPDX-License-Identifier: CC-BY-4.0
* SPDX-FileCopyrightText: 2026 Contributors to the Eclipse Foundation
* Source URL: <https://github.com/eclipse-tractusx/tractus-x-umbrella>
