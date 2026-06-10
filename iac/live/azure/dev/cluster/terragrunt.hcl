include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = {
    resource_group_name = "tx-umbrella"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "test"]
  skip_outputs                            = get_env("TG_DISABLE_BACKEND", "false") == "true"
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

  enable_import   = get_env("TG_ENABLE_IMPORT", "false")
  subscription_id = get_env("ARM_SUBSCRIPTION_ID", "")
  rg              = "tx-umbrella"
  cluster_name    = local.env_config.locals.cluster_name

  import_body = <<-EOT
    import {
      to = azurerm_kubernetes_cluster.this
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.ContainerService/managedClusters/${local.cluster_name}"
    }

    import {
      to = azurerm_kubernetes_cluster_node_pool.workloads
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.ContainerService/managedClusters/${local.cluster_name}/agentPools/workloads"
    }
  EOT

  import_contents = local.enable_import == "true" ? local.import_body : "# Imports disabled. Set TG_ENABLE_IMPORT=true to render import blocks.\n"
}

terraform {
  source = "../../../../modules/azure/cluster"
}

generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = local.import_contents
}

inputs = {
  resource_group_name   = dependency.resource_group.outputs.resource_group_name
  cluster_name          = local.env_config.locals.cluster_name
  kubernetes_version    = local.env_config.locals.kubernetes_version
  dns_prefix            = "tx-umbrella-dev"
  subnet_id             = dependency.networking.outputs.aks_subnet_id
  identity_id           = dependency.identity.outputs.identity_id
  identity_principal_id = dependency.identity.outputs.principal_id

  machine_type           = local.env_config.locals.system_vm_size
  node_count_system      = local.env_config.locals.node_count_system
  workloads_machine_type = local.env_config.locals.workloads_vm_size
  node_count_workloads   = local.env_config.locals.node_count_workloads
}
