provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  app_name      = "tx-umbrella"
  stage         = "dev"
  region        = "westeurope"
  dns_zone_name = "dev.tx-umbrella.example.com"
}

run "dns_zone_config" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone.this.name == "dev.tx-umbrella.example.com"
    error_message = "DNS zone name does not match"
  }

  assert {
    condition     = azurerm_private_dns_zone.this.resource_group_name == "rg-tx-umbrella-dev-we"
    error_message = "DNS zone resource group does not match the label convention"
  }
}
