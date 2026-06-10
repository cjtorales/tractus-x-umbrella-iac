provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  storage_account_name = "sactxumbrelladevwe"
  resource_group_name  = "rg-tx-umbrella-dev-we"
  location             = "westeurope"
}

run "storage_account_defaults" {
  command = plan

  assert {
    condition     = azurerm_storage_account.this.name == "sactxumbrelladevwe"
    error_message = "Storage account name does not match"
  }

  assert {
    condition     = azurerm_storage_account.this.account_tier == "Standard"
    error_message = "Account tier should default to Standard"
  }

  assert {
    condition     = azurerm_storage_account.this.account_replication_type == "LRS"
    error_message = "Replication should default to LRS"
  }

  assert {
    condition     = azurerm_storage_account.this.min_tls_version == "TLS1_2"
    error_message = "Min TLS version should default to TLS1_2"
  }

  assert {
    condition     = azurerm_storage_account.this.allow_nested_items_to_be_public == false
    error_message = "Public nested items should be disabled by default"
  }
}
