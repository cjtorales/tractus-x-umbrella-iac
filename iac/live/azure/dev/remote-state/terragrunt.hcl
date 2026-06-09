terraform_binary = "tofu"

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = {
    resource_group_name = "tx-umbrella"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  enable_import   = get_env("TG_ENABLE_IMPORT", "false")
  subscription_id = get_env("ARM_SUBSCRIPTION_ID", "")
  rg              = "tx-umbrella"
  sa              = "sttxumbrelladevtfstate"

  import_body = <<-EOT
    import {
      to = azurerm_storage_account.state
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Storage/storageAccounts/${local.sa}"
    }

    import {
      to = azurerm_storage_container.state
      id = "/subscriptions/${local.subscription_id}/resourceGroups/${local.rg}/providers/Microsoft.Storage/storageAccounts/${local.sa}/blobServices/default/containers/tfstate"
    }
  EOT

  import_contents = local.enable_import == "true" ? local.import_body : "# Imports disabled. Set TG_ENABLE_IMPORT=true to render import blocks.\n"
}

terraform {
  source = "../../../../modules/azure/remote-state"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "azurerm" {
  features {}
}
EOF
}

generate "imports" {
  path      = "imports.tf"
  if_exists = "overwrite"
  contents  = local.import_contents
}

remote_state {
  backend = "local"

  config = {
    path = "${get_terragrunt_dir()}/tofu.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = {
  region               = "westeurope"
  resource_group_name  = dependency.resource_group.outputs.resource_group_name
  storage_account_name = "sttxumbrelladevtfstate"
  container_name       = "tfstate"
  tags = {
    environment = "dev"
    managed-by  = "terragrunt"
    project     = "tx-umbrella"
  }
}
