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
