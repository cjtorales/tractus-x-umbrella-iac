include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = {
    resource_group_name = "tx-umbrella"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  enable_import   = get_env("TG_ENABLE_IMPORT", "false")
  subscription_id = get_env("ARM_SUBSCRIPTION_ID", "")
  rg              = "tx-umbrella"

  import_body = <<-EOT
    import {
      to = azurerm_user_assigned_identity.this
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-tx-umbrella-dev"
    }
  EOT

  import_contents = local.enable_import == "true" ? local.import_body : "# Imports disabled. Set TG_ENABLE_IMPORT=true to render import blocks.\n"
}

terraform {
  source = "../../../../modules/azure/identity"
}

generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = local.import_contents
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.resource_group_name
  identity_name       = "id-tx-umbrella-dev"
}
