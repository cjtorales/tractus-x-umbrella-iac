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

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  app_name               = "tx-umbrella"
  stage                  = "dev"
  region                 = "westeurope"
  kubernetes_version     = "1.30"
  subnet_id              = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tx-umbrella/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet"
  identity_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/tx-umbrella/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uai"
  identity_principal_id  = "11111111-1111-1111-1111-111111111111"
  machine_type           = "Standard_D2s_v3"
  node_count_system      = 2
  workloads_machine_type = "Standard_D4s_v3"
  node_count_workloads   = 2
}

run "cluster_config_is_correct" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.name == "aks-tx-umbrella-dev-we"
    error_message = "Cluster name does not match the label convention"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.location == "westeurope"
    error_message = "Region does not match"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.kubernetes_version == "1.30"
    error_message = "Kubernetes version does not match"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.sku_tier == "Free"
    error_message = "SKU tier should be Free"
  }
}

run "system_node_pool" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].node_count == 2
    error_message = "System node count should be 2"
  }

  assert {
    condition     = azurerm_kubernetes_cluster.this.default_node_pool[0].vm_size == "Standard_D2s_v3"
    error_message = "System VM size should be Standard_D2s_v3"
  }
}

run "workloads_node_pool" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.workloads.vm_size == "Standard_D4s_v3"
    error_message = "Workloads VM size should be Standard_D4s_v3"
  }

  assert {
    condition     = azurerm_kubernetes_cluster_node_pool.workloads.auto_scaling_enabled == true
    error_message = "Workloads pool should have autoscaling enabled"
  }
}

run "uses_user_assigned_identity" {
  command = plan

  assert {
    condition     = azurerm_kubernetes_cluster.this.identity[0].type == "UserAssigned"
    error_message = "Cluster should use a UserAssigned identity"
  }
}
