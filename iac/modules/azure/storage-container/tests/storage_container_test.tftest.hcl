provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  storage_container_name = "tfstate"
  storage_account_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Storage/storageAccounts/sac"
}

run "container_defaults" {
  command = plan

  assert {
    condition     = azurerm_storage_container.this.name == "tfstate"
    error_message = "Container name does not match"
  }

  assert {
    condition     = azurerm_storage_container.this.container_access_type == "private"
    error_message = "Container access type should default to private"
  }
}
