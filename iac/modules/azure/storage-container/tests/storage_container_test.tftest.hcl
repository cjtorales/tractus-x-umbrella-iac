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
  storage_container_name = "tfstate"
  storage_account_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sac"
}

run "container_defaults" {
  command = plan

  assert {
    condition     = azurerm_storage_container.this.name == "tfstate"
    error_message = "Container name does not match"
  }

  assert {
    condition     = azurerm_storage_container.this.container_access_type == "private"
    error_message = "Container access type should default to private"
  }
}
