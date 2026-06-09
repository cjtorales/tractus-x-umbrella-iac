resource "azurerm_user_assigned_identity" "this" {
  name                = var.identity_name
  location            = var.region
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
