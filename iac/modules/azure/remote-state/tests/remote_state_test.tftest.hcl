provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  region               = "westeurope"
  resource_group_name  = "tx-umbrella"
  storage_account_name = "sttxumbrelladevtfstate"
  container_name       = "tfstate"
}

run "storage_account_config" {
  command = plan

  assert {
    condition     = azurerm_storage_account.state.name == "sttxumbrelladevtfstate"
    error_message = "Storage account name does not match"
  }

  assert {
    condition     = azurerm_storage_account.state.account_replication_type == "LRS"
    error_message = "Replication should be LRS"
  }

  assert {
    condition     = azurerm_storage_account.state.min_tls_version == "TLS1_2"
    error_message = "Min TLS version should be TLS1_2"
  }

  assert {
    condition     = azurerm_storage_account.state.allow_nested_items_to_be_public == false
    error_message = "Public nested items should be disabled"
  }
}

run "container_config" {
  command = plan

  assert {
    condition     = azurerm_storage_container.state.name == "tfstate"
    error_message = "Container name does not match"
  }

  assert {
    condition     = azurerm_storage_container.state.container_access_type == "private"
    error_message = "Container should be private"
  }
}
