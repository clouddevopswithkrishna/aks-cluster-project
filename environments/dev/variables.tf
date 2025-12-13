variable "subscription_id" {
  description = "Access credentials for creating resources"
  type        = string
}

variable "environments" {
  type    = string
  default = "dev"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "dev-aks-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  type        = string
}

variable "address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "subnet_prefixes" {
  description = "Address prefixes for the subnet"
  type        = list(string)
}

# AKS Variables
variable "cluster_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
}

variable "enable_auto_scaling" {
  type    = bool
  default = true
}

# System Node Pool
variable "system_node_count" {
  type    = number
  default = 1
}

variable "system_min_count" {
  type    = number
  default = 1
}

variable "system_max_count" {
  type    = number
  default = 3
}

variable "system_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

# User Node Pool
variable "user_node_count" {
  type    = number
  default = 1
}

variable "user_min_count" {
  type    = number
  default = 1
}

variable "user_max_count" {
  type    = number
  default = 5
}

variable "user_vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

# ACR Variables
variable "acr_name" {
  type = string
}

variable "sku" {
  type    = string
  default = "Standard"
}

variable "admin_enabled" {
  type    = bool
  default = true
}
