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

output "vnet_name" {
  description = "Provisioned virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "vnet_id" {
  description = "Provisioned virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_name" {
  description = "Provisioned AKS subnet name."
  value       = azurerm_subnet.aks.name
}

output "aks_subnet_id" {
  description = "Provisioned AKS subnet ID."
  value       = azurerm_subnet.aks.id
}

output "network_security_group_id" {
  description = "Provisioned AKS subnet network security group ID."
  value       = azurerm_network_security_group.aks.id
}

output "resource_group_name" {
  description = "Networking resource group name."
  value       = local.rg
}
