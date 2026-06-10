module "name" {
  source        = "../label"
  resource_type = "azurerm_resource_group"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

resource "azurerm_resource_group" "this" {
  name     = module.name.resource_name
  location = var.region
  tags     = var.tags
}
