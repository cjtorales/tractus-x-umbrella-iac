provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variables {
  app_name = "tx-umbrella"
  stage    = "dev"
  region   = "westeurope"
}

run "composition_outputs" {
  command = plan

  assert {
    condition     = output.state_resource_group_name == "rg-tx-umbrella-dev-we"
    error_message = "State resource group name does not match the label convention"
  }

  assert {
    condition     = output.state_storage_account_name == "sactxumbrelladevwe"
    error_message = "State storage account name does not match the label convention"
  }

  assert {
    condition     = output.state_container_name == "tfstate"
    error_message = "State container name does not match"
  }
}
