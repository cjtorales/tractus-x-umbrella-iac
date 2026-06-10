terraform_binary = "tofu"

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env        = local.env_config.locals.environment
  region     = local.env_config.locals.region
  project    = local.env_config.locals.project

  # When TG_DISABLE_BACKEND=true, init skips the azurerm backend so static checks
  # (validate) work before the state storage account exists.
  disable_backend = get_env("TG_DISABLE_BACKEND", "false")
}

terraform {
  extra_arguments "conditional_backend" {
    commands  = ["init"]
    arguments = local.disable_backend == "true" ? ["-backend=false"] : []
  }

  before_hook "validate" {
    commands = ["apply"]
    execute  = ["tofu", "validate"]
  }

  after_hook "test" {
    commands = ["apply"]
    execute  = ["tofu", "test"]
  }
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
  region      = local.region
  environment = local.env
  tags = {
    environment = local.env
    managed-by  = "terragrunt"
    project     = local.project
  }
}
