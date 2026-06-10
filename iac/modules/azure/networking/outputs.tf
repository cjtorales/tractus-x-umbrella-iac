output "vnet_name" {
  description = "Provisioned virtual network name."
  value       = azurerm_virtual_network.this.name
}

output "vnet_id" {
  description = "Provisioned virtual network ID."
  value       = azurerm_virtual_network.this.id
}

output "aks_subnet_name" {
  description = "Provisioned AKS subnet name."
  value       = azurerm_subnet.aks.name
}

output "aks_subnet_id" {
  description = "Provisioned AKS subnet ID."
  value       = azurerm_subnet.aks.id
}

output "network_security_group_id" {
  description = "Provisioned AKS subnet network security group ID."
  value       = azurerm_network_security_group.aks.id
}

output "resource_group_name" {
  description = "Networking resource group name."
  value       = local.rg
}
