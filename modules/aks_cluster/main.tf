resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                         = "system"
    type                         = "VirtualMachineScaleSets"
    node_count                   = var.system_node_count
    min_count                    = var.enable_auto_scaling ? var.system_min_count : null
    max_count                    = var.enable_auto_scaling ? var.system_max_count : null
    vm_size                      = var.system_vm_size
    vnet_subnet_id               = var.vnet_subnet_id
    enable_auto_scaling          = var.enable_auto_scaling
    only_critical_addons_enabled = true # Dedicate to system pods
    orchestrator_version         = var.orchestrator_version != null ? var.orchestrator_version : var.kubernetes_version

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_vm_size
  node_count            = var.user_node_count
  min_count             = var.enable_auto_scaling ? var.user_min_count : null
  max_count             = var.enable_auto_scaling ? var.user_max_count : null
  vnet_subnet_id        = var.vnet_subnet_id
  enable_auto_scaling   = var.enable_auto_scaling
  mode                  = "User" # Indicates this is a user node pool
  orchestrator_version  = var.orchestrator_version != null ? var.orchestrator_version : var.kubernetes_version

  upgrade_settings {
    max_surge = "10%"
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}
