include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../../../modules/azure/dns"
}

inputs = {
  resource_group_name = "tx-umbrella"
  dns_zone_name       = local.env_config.locals.dns_zone_name
}
