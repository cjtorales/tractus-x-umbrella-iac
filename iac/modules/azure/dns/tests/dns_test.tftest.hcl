provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

variables {
  region              = "westeurope"
  resource_group_name = "tx-umbrella"
  dns_zone_name       = "dev.tx-umbrella.example.com"
}

run "dns_zone_config" {
  command = plan

  assert {
    condition     = azurerm_private_dns_zone.this.name == "dev.tx-umbrella.example.com"
    error_message = "DNS zone name does not match"
  }

  assert {
    condition     = azurerm_private_dns_zone.this.resource_group_name == "tx-umbrella"
    error_message = "DNS zone resource group does not match"
  }
}
