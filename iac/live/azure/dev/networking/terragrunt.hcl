include "root" {
  path = find_in_parent_folders("terragrunt.hcl")
}

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  enable_import   = get_env("TG_ENABLE_IMPORT", "false")
  subscription_id = get_env("ARM_SUBSCRIPTION_ID", "")
  rg              = "tx-umbrella"
  vnet            = "vnet-tx-umbrella-dev"
  subnet          = "snet-aks-dev"

  import_body = <<-EOT
    import {
      to = azurerm_virtual_network.this
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet}"
    }

    import {
      to = azurerm_network_security_group.aks
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Network/networkSecurityGroups/${local.subnet}-nsg"
    }

    import {
      to = azurerm_subnet.aks
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet}/subnets/${local.subnet}"
    }

    import {
      to = azurerm_subnet_network_security_group_association.aks
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Network/virtualNetworks/${local.vnet}/subnets/${local.subnet}"
    }
  EOT

  import_contents = local.enable_import == "true" ? local.import_body : "# Imports disabled. Set TG_ENABLE_IMPORT=true to render import blocks.\n"
}

terraform {
  source = "../../../../modules/azure/networking"
}

generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = local.import_contents
}

inputs = {
  resource_group_name = local.env_config.locals.resource_group_name
  vnet_name           = "vnet-tx-umbrella-dev"
  address_space       = local.env_config.locals.address_space
  aks_subnet_name     = "snet-aks-dev"
  aks_subnet_prefixes = local.env_config.locals.aks_subnet_prefixes
}
