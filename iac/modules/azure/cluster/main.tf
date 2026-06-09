resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.region
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  tags                = var.tags

  default_node_pool {
    name           = "system"
    vm_size        = var.machine_type
    node_count     = var.node_count_system
    vnet_subnet_id = var.subnet_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
  }

  role_based_access_control_enabled = true

  sku_tier = "Free"
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.identity_principal_id
}

resource "azurerm_kubernetes_cluster_node_pool" "workloads" {
  name                  = "workloads"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.workloads_machine_type
  vnet_subnet_id        = var.subnet_id

  auto_scaling_enabled = true
  node_count           = var.node_count_workloads
  min_count            = var.node_count_workloads
  max_count            = var.node_count_workloads + 2

  tags = var.tags
}
