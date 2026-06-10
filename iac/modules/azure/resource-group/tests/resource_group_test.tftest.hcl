provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  app_name = "tx-umbrella"
  stage    = "dev"
  region   = "westeurope"
}

run "creates_with_label_name" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this[0].name == "rg-tx-umbrella-dev-we"
    error_message = "Resource group name does not match the label convention"
  }

  assert {
    condition     = azurerm_resource_group.this[0].location == "westeurope"
    error_message = "Resource group region does not match"
  }
}

run "reuses_existing_when_not_created" {
  command = plan

  variables {
    create = false
    name   = "tx-umbrella"
  }

  assert {
    condition     = length(azurerm_resource_group.this) == 0
    error_message = "No resource group should be created when create = false"
  }

  assert {
    condition     = output.resource_group_name == "tx-umbrella"
    error_message = "Should output the existing resource group name"
  }
}
