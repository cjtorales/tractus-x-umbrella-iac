variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for identity resources."
  type        = string
}

variable "identity_name" {
  description = "Managed identity name."
  type        = string
}

variable "tags" {
  description = "Tags applied to identity resources."
  type        = map(string)
  default     = {}
}
