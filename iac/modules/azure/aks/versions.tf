terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "opentofu/azurerm"
      version = "4.57.0"
    }
  }
}
