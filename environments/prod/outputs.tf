output "resource_group_name" {
  value = module.resource_group.name
}

output "resource_group_location" {
  value = module.resource_group.location
}

output "aks_version" {
  value = module.aks_cluster.kubernetes_version
}

output "system_node_pool_version" {
  value = module.aks_cluster.system_node_pool_version
}

output "user_node_pool_version" {
  value = module.aks_cluster.user_node_pool_version
}

output "orchestrator_version" {
  value = module.aks_cluster.orchestrator_version
}
