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

module "label" {
  source        = "../label"
  resource_type = "azurerm_resource_group"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

locals {
  # Use the explicit name if provided, otherwise the label-generated one.
  name = var.name != "" ? var.name : module.label.resource_name
}

# Created only when var.create is true; otherwise an existing RG is reused.
resource "azurerm_resource_group" "this" {
  count    = var.create ? 1 : 0
  name     = local.name
  location = var.region
  tags     = var.tags
}
