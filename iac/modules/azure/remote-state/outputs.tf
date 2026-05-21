output "state_resource_group_name" {
  description = "Remote state resource group name."
  value       = var.resource_group_name
}

output "state_storage_account_name" {
  description = "Provisioned state storage account name."
  value       = azurerm_storage_account.state.name
}

output "state_container_name" {
  description = "Provisioned state container name."
  value       = azurerm_storage_container.state.name
}

output "state_resource_group_id" {
  description = "Resource group ID is not managed by this module when reusing an existing resource group."
  value       = null
}

output "state_storage_account_id" {
  description = "Provisioned state storage account ID."
  value       = azurerm_storage_account.state.id
}
