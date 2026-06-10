# The label module has no provider, so these tests run fully offline.

run "kebab_resource_group" {
  command = plan

  variables {
    resource_type = "azurerm_resource_group"
    app_name      = "tx-umbrella"
    stage         = "dev"
    location      = "westeurope"
  }

  assert {
    condition     = output.resource_name == "rg-tx-umbrella-dev-we"
    error_message = "kebab resource group name does not match"
  }
}

run "flat_storage_account_no_special_chars" {
  command = plan

  variables {
    resource_type      = "azurerm_storage_account"
    app_name           = "tx-umbrella"
    stage              = "dev"
    location           = "westeurope"
    naming_convention  = "flat"
    spec_chars_allowed = false
  }

  assert {
    condition     = output.resource_name == "sactxumbrelladevwe"
    error_message = "flat storage account name does not match"
  }
}

run "without_location" {
  command = plan

  variables {
    resource_type = "azurerm_kubernetes_cluster"
    app_name      = "tx-umbrella"
    stage         = "dev"
  }

  assert {
    condition     = output.resource_name == "aks-tx-umbrella-dev"
    error_message = "name without location should omit the geo code"
  }
}

run "unknown_prefix_falls_back" {
  command = plan

  variables {
    resource_type = "azurerm_something_unmapped"
    app_name      = "tx-umbrella"
    stage         = "dev"
  }

  assert {
    condition     = output.resource_name == "unk-tx-umbrella-dev"
    error_message = "unmapped resource type should use the 'unk' prefix"
  }
}
