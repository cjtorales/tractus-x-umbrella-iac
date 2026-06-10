output "resource_group_name" {
  description = "Resource group name (created or reused)."
  value       = local.name
}

output "resource_group_id" {
  description = "Resource group ID (null when reusing an existing one)."
  value       = one(azurerm_resource_group.this[*].id)
}
