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

# Composition: creates the resource group + state storage account + container by
# reusing the resource-group, storage-account and storage-container modules.
module "resource_group" {
  source   = "../resource-group"
  app_name = var.app_name
  stage    = var.stage
  region   = var.region
  create   = var.create_resource_group
  name     = var.resource_group_name
  tags     = var.tags
}

module "sa_name" {
  source             = "../label"
  resource_type      = "azurerm_storage_account"
  app_name           = var.app_name
  stage              = var.stage
  location           = var.region
  naming_convention  = "flat"
  spec_chars_allowed = false
}

module "storage_account" {
  source                   = "../storage-account"
  storage_account_name     = module.sa_name.resource_name
  resource_group_name      = module.resource_group.resource_group_name
  location                 = var.region
  account_replication_type = "LRS"
  tags                     = var.tags
}

module "storage_container" {
  source                 = "../storage-container"
  storage_container_name = var.container_name
  storage_account_id     = module.storage_account.id
}
