include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/azure/identity"
}

inputs = {
  resource_group_name = "tx-umbrella"
  identity_name       = "id-tx-umbrella-dev"
}
