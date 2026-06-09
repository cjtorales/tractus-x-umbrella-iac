output "resource_group_name" {
  description = "Provisioned resource group name."
  value       = azurerm_resource_group.this.name
}

output "resource_group_id" {
  description = "Provisioned resource group ID."
  value       = azurerm_resource_group.this.id
}

output "region" {
  description = "Resource group region."
  value       = azurerm_resource_group.this.location
}
