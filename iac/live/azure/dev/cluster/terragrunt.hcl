include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/azure/cluster"
}

inputs = {
  resource_group_name = "tx-umbrella"
  cluster_name        = local.env_config.locals.cluster_name
  kubernetes_version  = local.env_config.locals.kubernetes_version
  dns_prefix          = "tx-umbrella-dev"
  subnet_id           = dependency.networking.outputs.aks_subnet_id
}
