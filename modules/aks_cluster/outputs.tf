output "id" {
  value = azurerm_kubernetes_cluster.aks.id
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "kubernetes_version" {
  value = azurerm_kubernetes_cluster.aks.kubernetes_version
}

output "system_node_pool_version" {
  value = azurerm_kubernetes_cluster.aks.default_node_pool[0].orchestrator_version
}

output "user_node_pool_version" {
  value = azurerm_kubernetes_cluster_node_pool.user.orchestrator_version
}

output "orchestrator_version" {
  value = azurerm_kubernetes_cluster.aks.kubernetes_version
}
