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

variable "resource_group_name" {
  description = "Existing resource group name. Empty means generate it with the label module."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to identity resources."
  type        = map(string)
  default     = {}
}
