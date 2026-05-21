locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.environment
  location   = local.env_config.locals.location
  project    = local.env_config.locals.project
}

remote_state {
  backend = "azurerm"

  config = {
    resource_group_name  = local.env_config.locals.state_resource_group_name
    storage_account_name = local.env_config.locals.state_storage_account_name
    container_name       = local.env_config.locals.state_container_name
    key                  = "${path_relative_to_include()}/tofu.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
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

inputs = {
  location = local.location
  tags = {
    environment = local.env
    managed-by  = "terragrunt"
    project     = local.project
  }
}
