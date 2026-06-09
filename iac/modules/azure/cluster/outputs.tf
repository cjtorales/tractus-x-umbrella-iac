output "cluster_name" {
  description = "Provisioned AKS cluster name."
  value       = azurerm_kubernetes_cluster.this.name
}

output "kubernetes_version" {
  description = "Provisioned Kubernetes version."
  value       = azurerm_kubernetes_cluster.this.kubernetes_version
}

output "cluster_id" {
  description = "Provisioned AKS cluster ID."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_fqdn" {
  description = "Provisioned AKS cluster FQDN."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "cluster_endpoint" {
  description = "AKS API server endpoint (host)."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].host
  sensitive   = true
}

output "ca_certificate" {
  description = "Cluster CA certificate."
  value       = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "node_resource_group" {
  description = "Auto-generated node resource group for AKS."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "resource_group_name" {
  description = "Cluster resource group name."
  value       = var.resource_group_name
}
