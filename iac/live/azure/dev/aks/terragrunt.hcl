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

include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    aks_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.Network/virtualNetworks/mock/subnets/mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "test"]
  skip_outputs                            = get_env("TG_DISABLE_BACKEND", "false") == "true"
}

dependency "identity" {
  config_path = "../identity"

  mock_outputs = {
    identity_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock"
    principal_id = "00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "test"]
  skip_outputs                            = get_env("TG_DISABLE_BACKEND", "false") == "true"
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/azure//aks"
}

inputs = {
  kubernetes_version     = local.env_config.locals.kubernetes_version
  subnet_id              = dependency.networking.outputs.aks_subnet_id
  identity_id            = dependency.identity.outputs.identity_id
  identity_principal_id  = dependency.identity.outputs.principal_id
  machine_type           = local.env_config.locals.system_vm_size
  node_count_system      = local.env_config.locals.node_count_system
  workloads_machine_type = local.env_config.locals.workloads_vm_size
  node_count_workloads   = local.env_config.locals.node_count_workloads
  sku_tier               = local.env_config.locals.sku_tier
}
