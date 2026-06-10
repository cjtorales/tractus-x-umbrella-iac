locals {
  resource_prefixes = {
    resource_group         = "rg"
    storage_account        = "sac"
    storage_container      = "sc"
    virtual_network        = "vn"
    subnet                 = "sbn"
    network_security_group = "nsg"
    kubernetes_cluster     = "aks"
    user_assigned_identity = "uai"
    private_dns_zone       = "pdns"
    dns_zone               = "dns"
    container_registry     = "acr"
    key_vault              = "kv"
    log_analytics          = "law"
    public_ip              = "pip"
    nat_gateway            = "ng"
    route_table            = "rt"
  }

  azure_geo_codes = {
    ""                 = ""
    germanywestcentral = "gwc"
    germanynorth       = "gn"
    westeurope         = "we"
    northeurope        = "ne"
    francecentral      = "frc"
    switzerlandnorth   = "szn"
    swedencentral      = "sdc"
    uksouth            = "uks"
    ukwest             = "ukw"
    eastus             = "eus"
    eastus2            = "eus2"
    westus2            = "wus2"
    westus3            = "wus3"
    centralus          = "cus"
    brazilsouth        = "brs"
    australiaeast      = "ae"
    southeastasia      = "sea"
    eastasia           = "ea"
    japaneast          = "jpe"
  }

  # Map azurerm_<x> / azuread_<x> to a short prefix.
  resource_key = replace(replace(replace(var.resource_type, "azurerm_", ""), "azuread_", ""), "azapi_", "")
  prefix       = lower(lookup(local.resource_prefixes, local.resource_key, "unk"))

  parts = concat(
    [local.prefix, lower(var.app_name), lower(var.stage)],
    length(var.location) > 0 ? [lower(lookup(local.azure_geo_codes, lower(var.location), "unk"))] : []
  )

  separator = {
    pascal          = ""
    camel           = ""
    flat            = ""
    upper_flat      = ""
    snake           = "_"
    pascal_snake    = "_"
    camel_snake     = "_"
    screaming_snake = "_"
    kebab           = "-"
    train           = "-"
    cobol           = "-"
  }[var.naming_convention]

  cased = {
    flat            = lower(join(local.separator, local.parts))
    kebab           = lower(join(local.separator, local.parts))
    snake           = lower(join(local.separator, local.parts))
    cobol           = upper(join(local.separator, local.parts))
    upper_flat      = upper(join(local.separator, local.parts))
    screaming_snake = upper(join(local.separator, local.parts))
    pascal          = join(local.separator, [for w in local.parts : title(w)])
    pascal_snake    = join(local.separator, [for w in local.parts : title(w)])
    train           = join(local.separator, [for w in local.parts : title(w)])
    camel           = join(local.separator, [for i, w in local.parts : (i == 0 ? w : title(w))])
    camel_snake     = join(local.separator, [for i, w in local.parts : (i == 0 ? w : title(w))])
  }[var.naming_convention]

  final_resource_name = var.spec_chars_allowed ? local.cased : replace(replace(local.cased, "-", ""), "_", "")
}
