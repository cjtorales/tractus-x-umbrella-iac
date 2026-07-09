#  Copyright (c) 2026 Contributors to the Eclipse Foundation
#
#  See the NOTICE file(s) distributed with this work for additional
#  information regarding copyright ownership.
#
#  This program and the accompanying materials are made available under the
#  terms of the Apache License, Version 2.0 which is available at
#  https://www.apache.org/licenses/LICENSE-2.0.
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#  License for the specific language governing permissions and limitations
#  under the License.
#
#  SPDX-License-Identifier: Apache-2.0

output "cluster_name" {
  description = "Provisioned AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kubernetes_version" {
  description = "Provisioned Kubernetes version."
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "cluster_id" {
  description = "Provisioned AKS cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_fqdn" {
  description = "Provisioned AKS cluster FQDN."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "cluster_endpoint" {
  description = "AKS API server endpoint (host)."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "ca_certificate" {
  description = "Cluster CA certificate."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "node_resource_group" {
  description = "Auto-generated node resource group for AKS."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "resource_group_name" {
  description = "Cluster resource group name."
  value       = local.rg
}
