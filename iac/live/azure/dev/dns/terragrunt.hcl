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
  dns_zone_name   = local.env_config.locals.dns_zone_name

  import_body = <<-EOT
    import {
      to = azurerm_private_dns_zone.this
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Network/privateDnsZones/${local.dns_zone_name}"
    }
  EOT

  import_contents = local.enable_import == "true" ? local.import_body : "# Imports disabled. Set TG_ENABLE_IMPORT=true to render import blocks.\n"
}

terraform {
  source = "../../../../modules/azure/dns"
}

generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = local.import_contents
}

inputs = {
  resource_group_name = dependency.resource_group.outputs.resource_group_name
  dns_zone_name       = local.env_config.locals.dns_zone_name
}
