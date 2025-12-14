terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# 1. Resource Group Module
module "resource_group" {
  source              = "../../modules/resource_group"
  resource_group_name = var.resource_group_name
  location            = var.location
}

module "virtual_network" {
  source              = "../../modules/virtual_network"
  resource_group_name = module.resource_group.name
  vnet_name           = var.vnet_name
  address_space       = var.address_space
  location            = module.resource_group.location
}

module "subnet" {
  source               = "../../modules/subnet"
  resource_group_name  = module.resource_group.name
  virtual_network_name = module.virtual_network.name
  subnet_name          = var.subnet_name
  address_prefixes     = var.subnet_prefixes
}

module "aks_cluster" {
  source              = "../../modules/aks_cluster"
  cluster_name        = var.cluster_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  enable_auto_scaling = var.enable_auto_scaling

  # System Pool
  system_node_count = var.system_node_count
  system_min_count  = var.system_min_count
  system_max_count  = var.system_max_count
  system_vm_size    = var.system_vm_size

  # User Pool
  user_node_count = var.user_node_count
  user_min_count  = var.user_min_count
  user_max_count  = var.user_max_count
  user_vm_size    = var.user_vm_size

  vnet_subnet_id = module.subnet.id
}

module "container_registry" {
  source              = "../../modules/container_registry"
  acr_name            = var.acr_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
}
