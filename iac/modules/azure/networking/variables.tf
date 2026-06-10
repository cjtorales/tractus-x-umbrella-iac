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

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "aks_subnet_prefixes" {
  description = "Subnet prefixes used by AKS."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to networking resources."
  type        = map(string)
  default     = {}
}
