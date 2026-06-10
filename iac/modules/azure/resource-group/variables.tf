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

variable "create" {
  description = "Create the resource group (true) or reuse an existing one (false)."
  type        = bool
  default     = true
}

variable "name" {
  description = "Explicit resource group name. Empty means generate it with the label module."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags applied to the resource group."
  type        = map(string)
  default     = {}
}
