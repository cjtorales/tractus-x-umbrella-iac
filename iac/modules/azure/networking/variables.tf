variable "region" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for networking resources."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name."
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network."
  type        = list(string)
}

variable "aks_subnet_name" {
  description = "Subnet name used by AKS."
  type        = string
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
