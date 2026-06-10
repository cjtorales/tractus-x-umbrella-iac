provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  region              = "westeurope"
  resource_group_name = "tx-umbrella"
  identity_name       = "id-tx-umbrella-dev"
}

run "identity_config" {
  command = plan

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "id-tx-umbrella-dev"
    error_message = "Identity name does not match"
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.location == "westeurope"
    error_message = "Identity region does not match"
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.resource_group_name == "tx-umbrella"
    error_message = "Identity resource group does not match"
  }
}
