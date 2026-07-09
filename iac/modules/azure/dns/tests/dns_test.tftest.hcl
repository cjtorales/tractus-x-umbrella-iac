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
  app_name      = "tx-umbrella"
  stage         = "dev"
  region        = "westeurope"
  dns_zone_name = "dev.tx-umbrella.example.com"
}

run "dns_zone_config" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone.this.name == "dev.tx-umbrella.example.com"
    error_message = "DNS zone name does not match"
  }

  assert {
    condition     = azurerm_private_dns_zone.this.resource_group_name == "rg-tx-umbrella-dev-we"
    error_message = "DNS zone resource group does not match the label convention"
  }
}
