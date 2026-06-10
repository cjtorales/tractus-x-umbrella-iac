provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  app_name = "tx-umbrella"
  stage    = "dev"
  region   = "westeurope"
}

run "identity_config" {
  command = plan

  assert {
    condition     = azurerm_user_assigned_identity.this.name == "uai-tx-umbrella-dev-we"
    error_message = "Identity name does not match the label convention"
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.location == "westeurope"
    error_message = "Identity region does not match"
  }

  assert {
    condition     = azurerm_user_assigned_identity.this.resource_group_name == "rg-tx-umbrella-dev-we"
    error_message = "Identity resource group does not match the label convention"
  }
}
