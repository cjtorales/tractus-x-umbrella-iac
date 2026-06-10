terraform_binary = "tofu"

# Backend bootstrap (run once, locally). Composes resource-group + storage-account
# + storage-container to create the remote state backend. Uses a local backend.
locals {
  env_config = read_terragrunt_config("../../../live/azure/dev/env.hcl")
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
