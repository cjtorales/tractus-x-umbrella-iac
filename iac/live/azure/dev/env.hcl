locals {
  project     = "tx-umbrella"
  environment = "dev"
  region      = "germanywestcentral"

  resource_group_name   = "tx-umbrella"
  create_resource_group = false

  dns_zone_name       = "dev.tx-umbrella.com"
  kubernetes_version  = "1.30"
  address_space       = ["10.10.0.0/16"]
  aks_subnet_prefixes = ["10.10.1.0/24"]

  # Node pools
  system_vm_size       = "Standard_D2s_v3"
  node_count_system    = 2
  workloads_vm_size    = "Standard_D4s_v3"
  node_count_workloads = 2
}
