variable "cluster_name" {
  description = "AKS cluster name."
  type        = string
}

variable "region" {
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

variable "identity_id" {
  description = "User-assigned managed identity ID attached to the cluster."
  type        = string
}

variable "identity_principal_id" {
  description = "Principal ID of the user-assigned managed identity (for role assignment)."
  type        = string
}

variable "machine_type" {
  description = "VM size for the system node pool."
  type        = string
}

variable "node_count_system" {
  description = "Number of nodes in the system node pool."
  type        = number
}

variable "workloads_machine_type" {
  description = "VM size for the workloads node pool."
  type        = string
}

variable "node_count_workloads" {
  description = "Initial/min number of nodes in the workloads node pool."
  type        = number
}

variable "tags" {
  description = "Tags applied to cluster resources."
  type        = map(string)
  default     = {}
}
