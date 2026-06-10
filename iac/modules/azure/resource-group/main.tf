module "label" {
  source        = "../label"
  resource_type = "azurerm_resource_group"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

locals {
  # Use the explicit name if provided, otherwise the label-generated one.
  name = var.name != "" ? var.name : module.label.resource_name
}

# Created only when var.create is true; otherwise an existing RG is reused.
resource "azurerm_resource_group" "this" {
  count    = var.create ? 1 : 0
  name     = local.name
  location = var.region
  tags     = var.tags
}
