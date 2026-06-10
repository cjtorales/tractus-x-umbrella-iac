output "dns_zone_name" {
  description = "Provisioned DNS zone name."
  value       = azurerm_private_dns_zone.this.name
}

output "dns_zone_id" {
  description = "Provisioned DNS zone ID."
  value       = azurerm_private_dns_zone.this.id
}

output "resource_group_name" {
  description = "DNS resource group name."
  value       = local.rg
}
