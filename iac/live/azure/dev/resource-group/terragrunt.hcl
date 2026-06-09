terraform_binary = "tofu"

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  enable_import   = get_env("TG_ENABLE_IMPORT", "false")
  subscription_id = get_env("ARM_SUBSCRIPTION_ID", "")
  rg              = local.env_config.locals.resource_group_name

  import_body = <<-EOT
    import {
      to = azurerm_resource_group.this
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}"
    }
  EOT

  import_contents = local.enable_import == "true" ? local.import_body : "# Imports disabled. Set TG_ENABLE_IMPORT=true to render import blocks.\n"
}

terraform {
  source = "../../../../modules/azure/resource-group"
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

generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = local.import_contents
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
  region              = local.env_config.locals.region
  resource_group_name = local.env_config.locals.resource_group_name
  tags = {
    environment = local.env_config.locals.environment
    managed-by  = "terragrunt"
    project     = local.env_config.locals.project
  }
}
