variable "region" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the remote state backend."
  type        = string
}

variable "storage_account_name" {
  description = "Storage account name for remote state."
  type        = string
}

variable "container_name" {
  description = "Blob container name for remote state."
  type        = string
}

variable "tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default     = {}
}
