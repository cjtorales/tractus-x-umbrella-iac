output "state_resource_group_name" {
  description = "Remote state resource group name."
  value       = module.resource_group.resource_group_name
}

output "state_storage_account_name" {
  description = "Provisioned state storage account name."
  value       = module.storage_account.name
}

output "state_storage_account_id" {
  description = "Provisioned state storage account ID."
  value       = module.storage_account.id
}

output "state_container_name" {
  description = "Provisioned state container name."
  value       = module.storage_container.name
}
