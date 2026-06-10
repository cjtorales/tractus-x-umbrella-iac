provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  region              = "westeurope"
  resource_group_name = "tx-umbrella"
}

run "resource_group_config" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "tx-umbrella"
    error_message = "Resource group name does not match"
  }

  assert {
    condition     = azurerm_resource_group.this.location == "westeurope"
    error_message = "Resource group region does not match"
  }
}
