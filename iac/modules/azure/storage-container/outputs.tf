output "name" {
  description = "Storage container name."
  value       = azurerm_storage_container.this.name
}

output "id" {
  description = "Storage container ID."
  value       = azurerm_storage_container.this.id
}
