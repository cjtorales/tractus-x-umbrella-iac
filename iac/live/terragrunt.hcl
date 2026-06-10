terraform_binary = "tofu"

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  stage      = local.env_config.locals.environment
  region     = local.env_config.locals.region
  app_name   = local.env_config.locals.project

  # Backend resource names. These must match what the `label` module generates
  # (the Terragrunt remote_state block can't call a Terraform module), so the
  # same convention is reproduced here for the state RG + Storage Account only.
  geo_codes = {
    germanywestcentral = "gwc"
    germanynorth       = "gn"
    westeurope         = "we"
    northeurope        = "ne"
    eastus             = "eus"
    uksouth            = "uks"
    francecentral      = "frc"
    switzerlandnorth   = "szn"
    swedencentral      = "sdc"
  }
  geo                  = lookup(local.geo_codes, local.region, "unk")
  state_rg_name        = "rg-${local.app_name}-${local.stage}-${local.geo}"
  state_sa_name        = substr(lower("sac${replace(local.app_name, "-", "")}${local.stage}${local.geo}"), 0, 24)
  state_container_name = "tfstate"

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
    resource_group_name  = local.state_rg_name
    storage_account_name = local.state_sa_name
    container_name       = local.state_container_name
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
  region   = local.region
  app_name = local.app_name
  stage    = local.stage
  tags = {
    environment = local.stage
    managed-by  = "terragrunt"
    project     = local.app_name
  }
}
