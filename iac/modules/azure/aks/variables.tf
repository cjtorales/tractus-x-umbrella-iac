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

variable "kubernetes_version" {
  description = "Kubernetes version for AKS."
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

variable "sku_tier" {
  description = "AKS control plane SKU tier (Free = no SLA, Standard = SLA-backed control plane)."
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be one of: Free, Standard, Premium."
  }
}
