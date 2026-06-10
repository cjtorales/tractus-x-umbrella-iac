variable "resource_group_name" {
  description = "Resource group for DNS resources."
  type        = string
}

variable "dns_zone_name" {
  description = "Azure DNS zone name."
  type        = string
}

variable "tags" {
  description = "Tags applied to DNS resources."
  type        = map(string)
  default     = {}
}
