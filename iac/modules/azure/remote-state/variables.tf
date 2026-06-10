variable "region" {
  description = "Azure region."
  type        = string
}

variable "app_name" {
  description = "Application / project name (used for resource naming)."
  type        = string
}

variable "stage" {
  description = "Deployment stage (dev, staging, prod)."
  type        = string
}

variable "create_resource_group" {
  description = "Create the resource group (true) or reuse an existing one (false)."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Existing resource group name. Empty means generate it with the label module."
  type        = string
  default     = ""
}

variable "container_name" {
  description = "Blob container name for remote state."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags applied to backend resources."
  type        = map(string)
  default     = {}
}
