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





# 📝 Azure DevOps Pipeline Explanation (Terraform on Azure)

This document provides a detailed line-by-line explanation of the provided Azure DevOps YAML pipeline for managing infrastructure using Terraform.

---

## 1. Trigger and Parameters (Configuration)

This section defines what starts the pipeline and allows for user input when running it.

| Line(s) | Code | Explanation |
| :--- | :--- | :--- |
| `1-2` | `trigger: - main` | **Trigger:** The pipeline will automatically start a new run whenever a change is pushed to the `main` branch. |
| `4-11` | `parameters: ... environment: ... values: ...` | **Parameter: `environment`** Allows a user to select the target environment (`dev`, `test`, or `prod`) at runtime. It defaults to `dev`. |
| `12-16` | `parameters: ... terraformDestroy: ...` | **Parameter: `terraformDestroy`** A boolean (true/false) parameter that defaults to `false`. If set to `true`, it signals the pipeline to execute a `terraform destroy` (deletion of infrastructure). |

---

## 2. Pipeline Agent and Variables

This defines the execution environment and sets up global variables, including dynamic ones based on parameters.

| Line(s) | Code | Explanation |
| :--- | :--- | :--- |
| `18-19` | `pool: vmImage: 'ubuntu-latest'` | **Pool:** Specifies the execution environment (agent). In this case, it uses a Microsoft-hosted agent running the latest version of Ubuntu. |
| `22` | `serviceConnection: 'azure-connection-name'` | **Variable:** The name of the Azure Resource Manager service connection defined in Azure DevOps to authenticate with Azure. |
| `23-26` | `resourceGroup: ... container: ...` | **Backend Variables:** Variables defining the Azure Storage Account location used to store the Terraform state file (`.tfstate`). The `container` and `key` are dynamically named using the selected `environment` parameter. |
| `28-32` | `${{ if eq(parameters.terraformDestroy, true) }}: destroyFlag: ...` | **Conditional Variable:** This is a compile-time expression. If the `terraformDestroy` parameter is `true`, it sets `destroyFlag` to `'-destroy'` for use in the `terraform plan` command. Otherwise, it is an empty string. |

---

## 3. Stage 1: Validate (Code Quality and Syntax)

This stage ensures the Terraform code is syntactically correct and properly formatted.

| Line(s) | Code | Explanation |
| :--- | :--- | :--- |
| `36-44` | `jobs: - job: Lint ... - task: TerraformInstaller@0` | **Job: `Lint`** Installs the latest version of Terraform on the agent. |
| `45-47` | `script: terraform fmt -check -recursive` | **Step: Terraform Format Check** Executes the `terraform fmt -check` command, which checks if all Terraform files are properly formatted (linting). Fails if formatting errors are found. |
| `49-59` | `job: Validate ... dependsOn: Lint ... script: ... terraform init -backend=false ... terraform validate` | **Job: `Validate`** Runs after `Lint` succeeds. It performs a local `terraform init -backend=false` (no remote state config) followed by `terraform validate` to ensure the configuration is syntactically correct and self-consistent. |
| `58` | `workingDirectory: .../environments/$(environment)` | **Working Directory:** Specifies the path where the Terraform commands should run, dynamically set by the environment parameter. |

---

## 4. Stage 2: Plan (Remote State Setup and Planning)

This stage initializes the remote state and generates an execution plan for review.

| Line(s) | Code | Explanation |
| :--- | :--- | :--- |
| `62-64` | `- stage: Plan dependsOn: Validate` | **Stage Definition:** The planning stage. Only runs if the `Validate` stage succeeds. |
| `74-84` | `task: TerraformTaskV4@4 command: 'init' ...` | **Step: `Terraform Init`** Uses the Terraform task to run `terraform init`. It configures the Azure storage account for remote state management using the specified variables (Service Connection, Resource Group, Storage Account). |
| `86-94` | `task: ... command: 'plan' ... commandOptions: '-out=tfplan ... $(destroyFlag)'` | **Step: `Terraform Plan`** Generates an execution plan and saves it to the binary file `tfplan`. The `$(destroyFlag)` is injected to execute a normal plan or a destruction plan based on the user's input parameter. |
| `96-126` | `script: ... Analyze Plan ... name: SetVars` | **Step: `Analyze Plan`** A script that: 1. Converts the binary `tfplan` file into human-readable text using `terraform show`. 2. Constructs a message, including a destruction **WARNING** if applicable. 3. Sets an output variable, `PlanDetails`, containing this message. This output variable will be used in the next stage. |
| `127-130` | `publish: ... artifact: tfplan` | **Step: `Publish Plan Artifact`** Publishes the binary `tfplan` file as a pipeline artifact. This ensures the exact, tested plan is used for the application stage. |

---

## 5. Stage 3: Review (Manual Gate)

This stage pauses the pipeline and requires a manual gate before infrastructure changes are applied.

| Line(s) | Code | Explanation |
| :--- | :--- | :--- |
| `135-139` | `- job: WaitForValidation ... pool: server` | **Job: `WaitForValidation`** A server-type job used to host the Manual Validation task, as this step does not run on a standard agent. |
| `140` | `PlanDetails: $[ stageDependencies.Plan.Plan.outputs['SetVars.PlanDetails'] ]` | **Variable Retrieval:** Retrieves the human-readable plan text (`PlanDetails`) that was generated in the previous `Plan` stage. |
| `142-155` | `task: ManualValidation@0 ... instructions: ...` | **Step: `ManualValidation`** Pauses the pipeline for human review. The `instructions` input displays the `PlanDetails` variable, allowing the reviewer to see the exact changes or deletion actions planned before approving the run. It is set to reject the pipeline if it times out after 24 hours (`1440` minutes). |

---

## 6. Stage 4: Apply (Deployment)

This final stage applies the planned changes to the Azure infrastructure.

| Line(s) | Code | Explanation |
| :--- | :--- | :--- |
| `160-161` | `condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'), ne(variables['Build.Reason'], 'PullRequest'))` | **Conditional Gate (CRITICAL):** This stage only runs if: 1) The previous stage (`Review`) succeeded. 2) The build is on the **`main`** branch. 3) The build was **NOT** triggered by a Pull Request. This prevents accidental application from feature branches. |
| `162-167` | `jobs: - deployment: Apply ... environment: ...` | **Deployment Job:** Uses a `deployment` job, which is recommended for applying infrastructure changes and links the run to an Azure DevOps Environment resource. |
| `172-174` | `- download: current artifact: tfplan` | **Step: `Download Plan`** Downloads the exact binary `tfplan` artifact that was created and reviewed. |
| `182-192` | `task: TerraformTaskV4@4 command: 'init'` | **Step: `Terraform Init`** Re-initializes Terraform with the remote state configuration one last time before applying. |
| `202-210` | `task: TerraformTaskV4@4 command: 'apply' ... commandOptions: '$(Pipeline.Workspace)/tfplan/tfplan'` | **Step: `Terraform Apply`** Executes `terraform apply` using the downloaded plan file. This ensures that the only changes applied are those contained in the reviewed and approved plan file. |
