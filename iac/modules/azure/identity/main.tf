module "rg_name" {
  source        = "../label"
  resource_type = "azurerm_resource_group"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

module "name" {
  source        = "../label"
  resource_type = "azurerm_user_assigned_identity"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

locals {
  rg = var.resource_group_name != "" ? var.resource_group_name : module.rg_name.resource_name
}

resource "azurerm_user_assigned_identity" "this" {
  name                = module.name.resource_name
  location            = var.region
  resource_group_name = local.rg
  tags                = var.tags
}
