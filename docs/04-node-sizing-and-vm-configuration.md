# Node Sizing and VM Configuration (AKS)

<!-- TOC -->
* [1. Document Purpose](#1-document-purpose)
* [2. Current Configuration](#2-current-configuration)
  * [2.1 Per-Stage Values](#21-per-stage-values)
  * [2.2 VM Size Reference](#22-vm-size-reference)
* [3. Why Two Node Pools](#3-why-two-node-pools)
* [4. Why 1 Node per Pool Today (and Why That Should Change)](#4-why-1-node-per-pool-today-and-why-that-should-change)
* [5. Where to Change It](#5-where-to-change-it)
  * [5.1 Files Involved](#51-files-involved)
  * [5.2 Step by Step](#52-step-by-step)
* [6. Recommended Production Baseline](#6-recommended-production-baseline)
* [7. Related Documents](#7-related-documents)
<!-- TOC -->

---

## Metadata

* **Date:** 2026
* **Dependencies:** AKS, OpenTofu, Terragrunt
* **Target group:** Platform architecture, DevOps, Infrastructure engineering
* **Scope:** Azure only (`iac/modules/azure/aks`). Same pattern applies once GCP/AWS node pools are added.

---

## 1. Document Purpose

This document is the single reference for **VM sizes and node counts** used by the AKS clusters in
this repository, and for **where to change them** when an application's resource needs grow. It
complements [`03-deployment-architecture-and-diagrams.md`](03-deployment-architecture-and-diagrams.md#42-node-pools-and-workload-distribution),
which left VM size and node count as "to estimate per application" — this document fills those in
with the actual values currently deployed and the reasoning behind them.

## 2. Current Configuration

### 2.1 Per-Stage Values

Values live in `iac/live/azure/<stage>/env.hcl`, one block per stage:

| Stage | System pool VM size | System pool nodes | Workloads pool VM size | Workloads pool nodes (min / max) |
|---|---|---|---|---|
| `dev` | `Standard_D2s_v3` | 1 | `Standard_D4s_v3` | 1 / 3 |
| `test` | `Standard_D2s_v3` | 1 | `Standard_D4s_v3` | 1 / 3 |
| `prod` | *(not yet defined — create `iac/live/azure/prod/env.hcl` before first prod deploy)* | | | |

`max` for the workloads pool is not a separate variable — the module computes it as
`node_count_workloads + 2` (see [5.1](#51-files-involved)), so today's `min=1` gives `max=3`.

### 2.2 VM Size Reference

| VM size | vCPUs | RAM | Typical use in this repo |
|---|---|---|---|
| `Standard_D2s_v3` | 2 | 8 GiB | System pool — runs CoreDNS, kube-proxy, metrics-server and other cluster-critical add-ons. Kept small since it doesn't run application workloads. |
| `Standard_D4s_v3` | 4 | 16 GiB | Workloads pool — runs the actual Tractus-X Umbrella application pods. Sized larger since it carries the real load. |

Both are general-purpose, premium-storage-capable (`s`) v3 VMs — a reasonable default for a demo /
non-latency-critical workload. They are **not** a hard requirement: swap in `Standard_D8s_v3`,
`Standard_E*s_v5` (memory-optimized), etc. per the actual application's CPU/memory profile once
it's known. Use `az vm list-skus --location <region> --resource-type virtualMachines -o table` to
see what's available in the target region (`germanywestcentral` today).

## 3. Why Two Node Pools

The cluster always provisions **two separate node pools** (`iac/modules/azure/aks/main.tf`):

- **`system`** (`default_node_pool` on `azurerm_kubernetes_cluster`) — dedicated to Kubernetes
  system components. Never runs application pods.
- **`workloads`** (`azurerm_kubernetes_cluster_node_pool.workloads`) — dedicated to application
  pods, with `auto_scaling_enabled = true`.

This separation is intentional (see decision #2 in
[`03-deployment-architecture-and-diagrams.md` §4.3](03-deployment-architecture-and-diagrams.md#43-cluster-design-decisions)):
it stops a workload spike or crash-loop from starving cluster-critical components (DNS,
metrics, kube-proxy), and lets each pool scale and be sized independently.

## 4. Why 1 Node per Pool Today (and Why That Should Change)

Today `node_count_system = 1` and `node_count_workloads = 1` in every stage — **for demo purposes
only**, to keep the environments cheap while the platform is being validated.

**Recommendation: 2 nodes minimum per pool** before anything resembling a real workload runs on
these clusters:

- **System pool < 2 nodes** = no HA for CoreDNS / kube-proxy. A single node reboot, patch, or Azure
  maintenance event takes down cluster-internal DNS and networking for every namespace until it
  comes back.
- **Workloads pool < 2 nodes** = no HA for the application itself, and `az.kubernetes.io` pod
  topology / anti-affinity rules have nothing to spread across — a single node failure takes the
  whole workload down, and node upgrades/drains have nowhere to reschedule pods.

This is a **config change, not a code change** — see [5.2](#52-step-by-step).

## 5. Where to Change It

### 5.1 Files Involved

```
iac/live/azure/<stage>/env.hcl              <- values to edit (per stage)
  ├── system_vm_size          -> module var "machine_type"
  ├── node_count_system       -> module var "node_count_system"
  ├── workloads_vm_size       -> module var "workloads_machine_type"
  └── node_count_workloads    -> module var "node_count_workloads"

iac/live/azure/<stage>/aks/terragrunt.hcl   <- wires env.hcl values into the module (no edits needed to resize)

iac/modules/azure/aks/variables.tf          <- variable definitions/types (edit only to add new knobs)
iac/modules/azure/aks/main.tf               <- where vm_size / node_count are actually applied:
                                                - default_node_pool block (system)
                                                - azurerm_kubernetes_cluster_node_pool.workloads
                                                  (min_count = node_count_workloads,
                                                   max_count = node_count_workloads + 2)
```

To resize an existing stage, you only ever need to touch `env.hcl` — the module and terragrunt
wiring already support any `vm_size` / node count combination.

### 5.2 Step by Step

1. Edit `iac/live/azure/<stage>/env.hcl`, e.g. bump `node_count_system` / `node_count_workloads`
   to `2`, or change `system_vm_size`/`workloads_vm_size` to a larger SKU.
2. Open a PR — `iac-validate` and `iac-plan` run automatically and post the plan (node count /
   size change) as a PR comment. Review it: a VM size change **replaces** the node pool
   (`vm_size` forces recreation), while a node **count** change is an in-place scale.
3. Merge to `main`. `iac-apply` promotes the change `dev -> test -> prod`, applying `dev`
   directly and pausing for manual approval on `test`/`prod` (see
   [`.github/workflows/README.md`](../.github/workflows/README.md)).
4. Confirm node count in the cluster: `kubectl get nodes -o wide` or
   `az aks nodepool list --cluster-name <cluster> --resource-group <rg> -o table`.

## 6. Recommended Production Baseline

Once a `prod` stage is created, don't just copy `dev`/`test` values — size it for the real
application profile and availability needs:

| Setting | Dev / Test (current) | Suggested prod starting point |
|---|---|---|
| System pool nodes | 1 | **2–3** (HA for cluster add-ons; odd counts help node-level etcd/kube-system spread) |
| Workloads pool nodes (min) | 1 | **2+** (HA for application pods) |
| Workloads pool nodes (max) | `min + 2` (fixed) | Size to expected peak load; consider making the `+2` headroom configurable per stage if prod needs a wider autoscaling range |
| `sku_tier` | `Free` (no control-plane SLA) | Consider `Standard` for prod — adds an SLA-backed control plane |

`sku_tier` is currently hardcoded to `"Free"` in `iac/modules/azure/aks/main.tf` (not exposed as a
variable) — expose it as a module input if prod needs `Standard`.

## 7. Related Documents

* [`03-deployment-architecture-and-diagrams.md`](03-deployment-architecture-and-diagrams.md) —
  overall cluster architecture; §4 (Internal Cluster Architecture) and §4.3 (Cluster Design
  Decisions) give the broader rationale for the node pool split this document details.
* [`.github/workflows/README.md`](../.github/workflows/README.md) — how a config change in
  `env.hcl` actually rolls out through `validate -> plan -> apply`, and how to destroy a stage
  entirely if it needs to be rebuilt with new sizing from scratch.
