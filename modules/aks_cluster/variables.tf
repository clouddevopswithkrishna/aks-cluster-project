variable "cluster_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version"
  default     = null # If null, uses latest non-preview
}

variable "vnet_subnet_id" {
  type = string
}

variable "enable_auto_scaling" {
  type    = bool
  default = true
}

variable "orchestrator_version" {
  type        = string
  description = "Orchestrator version for node pools"
  default     = null
}

# Network Profile Variables
variable "service_cidr" {
  default = "10.255.0.0/16"
}

variable "dns_service_ip" {
  default = "10.255.0.10"
}

# System Node Pool Variables
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

# User Node Pool Variables
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
