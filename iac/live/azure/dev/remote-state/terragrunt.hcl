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
  location             = "germanywestcentral"
  resource_group_name  = "tx-umbrella"
  storage_account_name = "sttxumbrelladevtfstate"
  container_name       = "tfstate"
  tags = {
    environment = "dev"
    managed-by  = "terragrunt"
    project     = "tx-umbrella"
  }
}
