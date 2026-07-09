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
  app_name = "tx-umbrella"
  stage    = "dev"
  region   = "westeurope"
}

run "creates_with_label_name" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this[0].name == "rg-tx-umbrella-dev-we"
    error_message = "Resource group name does not match the label convention"
  }

  assert {
    condition     = azurerm_resource_group.this[0].location == "westeurope"
    error_message = "Resource group region does not match"
  }
}

run "reuses_existing_when_not_created" {
  command = plan

  variables {
    create = false
    name   = "tx-umbrella"
  }

  assert {
    condition     = length(azurerm_resource_group.this) == 0
    error_message = "No resource group should be created when create = false"
  }

  assert {
    condition     = output.resource_group_name == "tx-umbrella"
    error_message = "Should output the existing resource group name"
  }
}
