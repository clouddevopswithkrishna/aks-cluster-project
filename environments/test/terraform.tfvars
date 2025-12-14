subscription_id     = "202d4be6-e0dd-4b9e-84b7-e235d53271a8"
environments        = "test"
resource_group_name = "test-aks-rg"
location            = "Central India"
vnet_name           = "test-aks-vnet"
address_space       = ["10.1.0.0/16"]

subnet_name     = "test-aks-subnet"
subnet_prefixes = ["10.1.0.0/24"]

cluster_name       = "test-aks-cluster"
dns_prefix         = "testaks"
kubernetes_version = "1.32.3"

system_node_count = 2
system_min_count  = 2
system_max_count  = 3
system_vm_size    = "Standard_D2s_v3"

user_node_count = 2
user_min_count  = 2
user_max_count  = 5
user_vm_size    = "Standard_D2s_v3"

acr_name      = "testacrregistrybala01"
sku           = "Standard"
admin_enabled = true
