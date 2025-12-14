subscription_id     = "202d4be6-e0dd-4b9e-84b7-e235d53271a8"
environments        = "prod"
resource_group_name = "prod-aks-rg"
location            = "Central India"
vnet_name           = "prod-aks-vnet"
address_space       = ["10.2.0.0/16"]

subnet_name     = "prod-aks-subnet"
subnet_prefixes = ["10.2.0.0/24"]

cluster_name       = "prod-aks-cluster"
dns_prefix         = "prodaks"
kubernetes_version = "1.32.3"

system_node_count = 3
system_min_count  = 3
system_max_count  = 5
system_vm_size    = "Standard_D4s_v3"

user_node_count = 3
user_min_count  = 3
user_max_count  = 10
user_vm_size    = "Standard_D4s_v3"

acr_name      = "prodacrregistrybala01"
sku           = "Premium"
admin_enabled = true
