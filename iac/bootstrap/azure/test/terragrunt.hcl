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

terraform_binary = "tofu"

# Backend bootstrap (run once, locally). Composes resource-group + storage-account
# + storage-container to create the remote state backend. Uses a local backend.
locals {
  env_config = read_terragrunt_config("../../../live/azure/test/env.hcl")
}

terraform {
  source = "../../../modules/azure//remote-state"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

remote_state {
  backend = "local"

  config = {
    path = "${get_terragrunt_dir()}/tofu.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  region                = local.env_config.locals.region
  app_name              = local.env_config.locals.project
  stage                 = local.env_config.locals.environment
  resource_group_name   = lookup(local.env_config.locals, "resource_group_name", "")
  create_resource_group = lookup(local.env_config.locals, "create_resource_group", true)
  tags = {
    environment = local.env_config.locals.environment
    managed-by  = "terragrunt"
    project     = local.env_config.locals.project
  }
}
