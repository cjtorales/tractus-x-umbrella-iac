locals {
  environment = "dev"
  project     = "tx-umbrella"
  location    = "germanywestcentral"

  # Remote backend placeholders. Update these values once the state storage exists.
  state_resource_group_name  = "tx-umbrella"
  state_storage_account_name = "sttxumbrelladevtfstate"
  state_container_name       = "tfstate"

  cluster_name        = "aks-tx-umbrella-dev"
  dns_zone_name       = "dev.tx-umbrella.example.com"
  tenant_id           = "9409749f-4c5e-4afb-a956-0957b9e55e24"
  kubernetes_version  = "1.30"
  address_space       = ["10.10.0.0/16"]
  aks_subnet_prefixes = ["10.10.1.0/24"]
}
