# AKS Cluster Project with Terraform

This project provisions a production-ready Azure Kubernetes Service (AKS) cluster using Terraform, featuring distinct system and user node pools, auto-scaling, and version control.

## Project Structure

```
aks-cluster-project/
├── modules/
│   ├── aks_cluster/        # Core AKS module
│   ├── container_registry/ # ACR module
│   ├── resource_group/     # Resource Group module
│   ├── virtual_network/    # VNet module
│   └── subnet/             # Subnet module
├── environments/
│   ├── dev/                # Development environment
│   ├── test/               # Test environment
│   └── prod/               # Production environment
└── README.md
```

## Features

-   **Modular Design**: Reusable modules for atomic resource management.
-   **Separate Node Pools**:
    -   **System Pool**: Dedicated for system pods (Critical Addons Only).
    -   **User Pool**: Dedicated for application workloads (`mode = "User"`).
-   **Auto-Scaling**: Configurable `min_count` and `max_count` for all node pools.
-   **Version Control**:
    -   Explicit `kubernetes_version` for the cluster control plane.
    -   Configurable `orchestrator_version` for node pools (defaults to cluster version).
-   **Remote State**: Configured to use Azure Storage Account for backend state (currently local for validation).

## Module Inputs

The `aks_cluster` module accepts the following key variables:

| Variable | Description | Default |
| :--- | :--- | :--- |
| `cluster_name` | Name of the AKS cluster | Required |
| `kubernetes_version` | Control plane version (e.g., "1.32.0") | `null` (Use latest) |
| `orchestrator_version` | Node pool version (optional, overrides k8s version) | `null` |
| `enable_auto_scaling` | Enable VMSS auto-scaling | `true` |
| `system_node_count` | Initial node count for **System** pool | `1` |
| `system_min_count` | Min nodes for System pool auto-scaling | `1` |
| `system_max_count` | Max nodes for System pool auto-scaling | `3` |
| `user_node_count` | Initial node count for **User** pool | `1` |
| `user_min_count` | Min nodes for User pool auto-scaling | `1` |
| `user_max_count` | Max nodes for User pool auto-scaling | `5` |

## Outputs

The project exposes the following outputs for verification:

-   `aks_version`: The Kubernetes version of the control plane.
-   `orchestrator_version`: The orchestrator version used by the node pools.
-   `system_node_pool_version`: The version running on the system node pool.
-   `user_node_pool_version`: The version running on the user node pool.

## Deployment Instructions

### Prerequisites
-   Azure CLI installed and authenticated (`az login`)
-   Terraform installed

### 1. Initialize
Navigate to your desired environment directory (e.g., `environments/dev`) and initialize Terraform:

```bash
cd environments/dev
terraform init
```

### 2. Plan
Preview the changes to be applied:

```bash
terraform plan
```

Ensure the plan shows the expected node pool counts and versions.

### 3. Apply
Provision the infrastructure:

```bash
terraform apply
```

## Environment Configuration

| Environment | System Pool | User Pool | Auto-Scaling |
| :--- | :--- | :--- | :--- |
| **Dev** | 1 (Min 1, Max 3) | 1 (Min 1, Max 5) | Enabled |
| **Test** | 2 (Min 2, Max 3) | 2 (Min 2, Max 5) | Enabled |
| **Prod** | 3 (Min 3, Max 5) | 3 (Min 3, Max 10) | Enabled |

