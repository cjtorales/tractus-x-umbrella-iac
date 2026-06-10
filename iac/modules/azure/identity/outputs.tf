output "identity_name" {
  description = "Provisioned managed identity name."
  value       = azurerm_user_assigned_identity.this.name
}

output "identity_id" {
  description = "Provisioned managed identity resource ID."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "Provisioned managed identity principal ID."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "Provisioned managed identity client ID."
  value       = azurerm_user_assigned_identity.this.client_id
}

output "resource_group_name" {
  description = "Identity resource group name."
  value       = local.rg
}
