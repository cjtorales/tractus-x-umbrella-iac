output "name" {
  description = "Storage account name."
  value       = azurerm_storage_account.this.name
}

output "id" {
  description = "Storage account ID."
  value       = azurerm_storage_account.this.id
}
