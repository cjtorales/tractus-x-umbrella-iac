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

output "dns_zone_name" {
  description = "Provisioned DNS zone name."
  value       = azurerm_private_dns_zone.this.name
}

output "dns_zone_id" {
  description = "Provisioned DNS zone ID."
  value       = azurerm_private_dns_zone.this.id
}

output "resource_group_name" {
  description = "DNS resource group name."
  value       = local.rg
}
