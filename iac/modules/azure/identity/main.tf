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

resource "azurerm_user_assigned_identity" "this" {
  name                = module.name.resource_name
  location            = var.region
  resource_group_name = module.rg_name.resource_name
  tags                = var.tags
}
