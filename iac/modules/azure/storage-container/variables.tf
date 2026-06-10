variable "storage_container_name" {
  description = "Storage container name."
  type        = string
}

variable "storage_account_id" {
  description = "ID of the storage account the container is created in."
  type        = string
}

variable "container_access_type" {
  description = "Access level for the container (private, blob, container)."
  type        = string
  default     = "private"
}
