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
  app_name            = "tx-umbrella"
  stage               = "dev"
  region              = "westeurope"
  address_space       = ["10.10.0.0/16"]
  aks_subnet_prefixes = ["10.10.1.0/24"]
}

run "vnet_config" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.name == "vn-tx-umbrella-dev-we"
    error_message = "VNet name does not match the label convention"
  }

  assert {
    condition     = contains(azurerm_virtual_network.this.address_space, "10.10.0.0/16")
    error_message = "VNet address space does not match"
  }

  assert {
    condition     = azurerm_virtual_network.this.location == "westeurope"
    error_message = "VNet region does not match"
  }
}

run "subnet_and_nsg" {
  command = plan

  assert {
    condition     = azurerm_subnet.aks.name == "sbn-tx-umbrella-dev-we"
    error_message = "Subnet name does not match the label convention"
  }

  assert {
    condition     = contains(azurerm_subnet.aks.address_prefixes, "10.10.1.0/24")
    error_message = "Subnet prefix does not match"
  }

  assert {
    condition     = azurerm_network_security_group.aks.name == "sbn-tx-umbrella-dev-we-nsg"
    error_message = "NSG name should be <subnet>-nsg"
  }
}
