variable "cluster_name" {
  description = "AKS cluster name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the AKS cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for AKS."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes."
  type        = string
}

variable "tags" {
  description = "Tags applied to cluster resources."
  type        = map(string)
  default     = {}
}
