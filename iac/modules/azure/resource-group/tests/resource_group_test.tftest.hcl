provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  app_name = "tx-umbrella"
  stage    = "dev"
  region   = "westeurope"
}

run "resource_group_config" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "rg-tx-umbrella-dev-we"
    error_message = "Resource group name does not match the label convention"
  }

  assert {
    condition     = azurerm_resource_group.this.location == "westeurope"
    error_message = "Resource group region does not match"
  }
}
