provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  region              = "westeurope"
  resource_group_name = "tx-umbrella"
  vnet_name           = "vnet-tx-umbrella-dev"
  address_space       = ["10.10.0.0/16"]
  aks_subnet_name     = "snet-aks-dev"
  aks_subnet_prefixes = ["10.10.1.0/24"]
}

run "vnet_config" {
  command = plan

  assert {
    condition     = azurerm_virtual_network.this.name == "vnet-tx-umbrella-dev"
    error_message = "VNet name does not match"
  }

  assert {
    condition     = azurerm_virtual_network.this.address_space[0] == "10.10.0.0/16"
    error_message = "VNet address space does not match"
  }

  assert {
    condition     = azurerm_virtual_network.this.location == "westeurope"
    error_message = "VNet region does not match"
  }
}

run "subnet_and_nsg" {
  command = plan

  assert {
    condition     = azurerm_subnet.aks.address_prefixes[0] == "10.10.1.0/24"
    error_message = "Subnet prefix does not match"
  }

  assert {
    condition     = azurerm_network_security_group.aks.name == "snet-aks-dev-nsg"
    error_message = "NSG name should be <subnet>-nsg"
  }
}
