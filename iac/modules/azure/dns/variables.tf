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

variable "dns_zone_name" {
  description = "Private DNS zone name (a domain, not name-generated)."
  type        = string
}

variable "tags" {
  description = "Tags applied to DNS resources."
  type        = map(string)
  default     = {}
}
