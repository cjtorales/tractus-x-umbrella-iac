module "rg_name" {
  source        = "../label"
  resource_type = "azurerm_resource_group"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

module "vnet_name" {
  source        = "../label"
  resource_type = "azurerm_virtual_network"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

module "subnet_name" {
  source        = "../label"
  resource_type = "azurerm_subnet"
  app_name      = var.app_name
  stage         = var.stage
  location      = var.region
}

locals {
  rg = var.resource_group_name != "" ? var.resource_group_name : module.rg_name.resource_name
}

resource "azurerm_virtual_network" "this" {
  name                = module.vnet_name.resource_name
  location            = var.region
  resource_group_name = local.rg
  address_space       = var.address_space
  tags                = var.tags
}

resource "azurerm_network_security_group" "aks" {
  name                = "${module.subnet_name.resource_name}-nsg"
  location            = var.region
  resource_group_name = local.rg
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name                 = module.subnet_name.resource_name
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.aks_subnet_prefixes
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}
