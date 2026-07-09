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

# The label module has no provider, so these tests run fully offline.

run "kebab_resource_group" {
  command = plan

  variables {
    resource_type = "azurerm_resource_group"
    app_name      = "tx-umbrella"
    stage         = "dev"
    location      = "westeurope"
  }

  assert {
    condition     = output.resource_name == "rg-tx-umbrella-dev-we"
    error_message = "kebab resource group name does not match"
  }
}

run "flat_storage_account_no_special_chars" {
  command = plan

  variables {
    resource_type      = "azurerm_storage_account"
    app_name           = "tx-umbrella"
    stage              = "dev"
    location           = "westeurope"
    naming_convention  = "flat"
    spec_chars_allowed = false
  }

  assert {
    condition     = output.resource_name == "sactxumbrelladevwe"
    error_message = "flat storage account name does not match"
  }
}

run "without_location" {
  command = plan

  variables {
    resource_type = "azurerm_kubernetes_cluster"
    app_name      = "tx-umbrella"
    stage         = "dev"
  }

  assert {
    condition     = output.resource_name == "aks-tx-umbrella-dev"
    error_message = "name without location should omit the geo code"
  }
}

run "unknown_prefix_falls_back" {
  command = plan

  variables {
    resource_type = "azurerm_something_unmapped"
    app_name      = "tx-umbrella"
    stage         = "dev"
  }

  assert {
    condition     = output.resource_name == "unk-tx-umbrella-dev"
    error_message = "unmapped resource type should use the 'unk' prefix"
  }
}
