# Composition: creates the resource group + state storage account + container by
# reusing the resource-group, storage-account and storage-container modules.
module "resource_group" {
  source   = "../resource-group"
  app_name = var.app_name
  stage    = var.stage
  region   = var.region
  tags     = var.tags
}

module "sa_name" {
  source             = "../label"
  resource_type      = "azurerm_storage_account"
  app_name           = var.app_name
  stage              = var.stage
  location           = var.region
  naming_convention  = "flat"
  spec_chars_allowed = false
}

module "storage_account" {
  source                   = "../storage-account"
  storage_account_name     = module.sa_name.resource_name
  resource_group_name      = module.resource_group.resource_group_name
  location                 = var.region
  account_replication_type = "LRS"
  tags                     = var.tags
}

module "storage_container" {
  source                 = "../storage-container"
  storage_container_name = var.container_name
  storage_account_id     = module.storage_account.id
}
