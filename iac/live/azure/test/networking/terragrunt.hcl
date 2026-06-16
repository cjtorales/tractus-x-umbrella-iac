include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/azure//networking"
}

inputs = {
  address_space       = local.env_config.locals.address_space
  aks_subnet_prefixes = local.env_config.locals.aks_subnet_prefixes
}
