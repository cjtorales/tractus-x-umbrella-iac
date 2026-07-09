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

output "identity_name" {
  description = "Provisioned managed identity name."
  value       = azurerm_user_assigned_identity.this.name
}

output "identity_id" {
  description = "Provisioned managed identity resource ID."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Provisioned managed identity principal ID."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Provisioned managed identity client ID."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "resource_group_name" {
  description = "Identity resource group name."
  value       = local.rg
}
