# Azure AKS Pipeline: Complete Implementation & Setup Guide

This document provides a complete breakdown of the implementation logic, code structure, and setup steps for the Azure Kubernetes Service (AKS) CI/CD solution.

---

## 🏗️ Phase 1: Infrastructure Implementation

We implemented a modular Terraform design to support production-grade AKS requirements.

### 1.1 AKS Module Design (`modules/aks_cluster`)
*   **Split Node Pools**:
    *   **System Pool**: Hosts critical internal pods (CoreDNS, metrics-server). configured with `only_critical_addons_enabled = true`.
    *   **User Pool**: Dedicated to application workloads, configured with `mode = "User"`.
*   **Auto-Scaling**: Enabled via `enable_auto_scaling = true`, allowing pools to scale between `min_count` and `max_count`.
*   **Explicit Version control**:
    *   `kubernetes_version`: Controls the Control Plane.
    *   `orchestrator_version`: Controls individual Node Pools (System/User).

### 1.2 Environment Isolation
*   **Dynamic Backends**: State files are separated by environment key (`dev.terraform.tfstate`, `test...`, `prod...`).
*   **Variable Separation**: Each environment (`dev`, `test`, `prod`) has its own `terraform.tfvars` file defining specific node counts and VM sizes.

---

## 🚀 Phase 2: Pipeline Implementation Logic

The `azure-pipelines.yml` implements a "Safe Deployment" strategy using three key logical components.

### 2.1 Dynamic Environment Selection
**Goal**: Ensure a pipeline run touches ONLY the intended environment.
**Implementation**:
*   **Parameters**: Added `parameters` block to allow selection of `dev`, `test`, or `prod` at runtime.
*   **Variables**: Mapped `$(environment)` and `$(key)` to `${{ parameters.environment }}`.
*   **Deployment Job**: The `environment` property uses the parameter, routing approvals to the correct scope.

### 2.2 Plan Analysis Engine
**Goal**: Provide the approver with human-readable context, not just raw logs.
**Implementation**:
1.  **Generate JSON**: `terraform show -json tfplan > tfplan.json`
2.  **Parse with JQ**: We extract specific fields (Name, Action, Version, Node Count) for resources of type `azurerm_kubernetes_cluster*`.
3.  **Publish Variable**: The extracted text is saved as a pipeline output variable (`PlanDetails`) for the next stage.

### 2.3 Smart Manual Validation
**Goal**: Force specific "Eyes-on-Glass" validation before applying changes.
**Implementation**:
*   Used the `ManualValidation@0` task in a serverless job.
*   **Inputs**: The `instructions` field is injected with the dynamic `$(PlanDetails)` variable.
*   **Outcome**: The approval dialog shows exactly what will change (e.g., "Upgrading Node Pool to 1.32.3").

---

## 🛠️ Phase 3: Setup Instructions

Follow these steps to configure Azure and Azure DevOps to run the solution.

### Step 1: Create Terraform Backend (Azure)
Run these commands locally to create the state storage.

```bash
# 1. Login
az login

# 2. Create Resource Group
az group create --name terraform-state-rg --location centralindia

# 3. Create Storage Account (globally unique name)
az storage account create \
  --resource-group terraform-state-rg \
  --name tfstateunique12345 \
  --sku Standard_LRS \
  --encryption-services blob

# 4. Create Container
az storage container create --name tfstate --account-name tfstateunique12345
```

### Step 2: Configure Service Connection (Azure DevOps)
1.  Go to **Project Settings** -> **Pipelines** -> **Service connections**.
2.  Click **New service connection** -> **Azure Resource Manager**.
3.  Choose **Workload Identity federation**.
4.  Select Subscription.
5.  Name it: `azure-connection-name`.
6.  **Important**: Check "Grant access permission to all pipelines".

### Step 3: Configure Environments & Approvals (Azure DevOps)
*You must do this for `dev`, `test`, and `prod`.*

1.  Go to **Pipelines** -> **Environments**.
2.  Create Environment: `dev`.
3.  Open `dev` -> Click **⋮** -> **Approvals and checks**.
4.  Add **Approvals**.
5.  Assign yourself or your team.
6.  *Repeat for `test` and `prod`.*

### Step 4: Import Pipeline
1.  Go to **Pipelines** -> **New pipeline**.
2.  Select **Azure Repos Git** -> Select Repo.
3.  Select **Existing Azure Pipelines YAML file**.
4.  Path: `/azure-pipelines.yml`.
5.  Save.

---

## ▶️ Phase 4: Execution

1.  Click **Run Pipeline**.
2.  Select **Target Environment** (e.g., `prod`).
3.  Wait for **Validation** and **Plan** stages to complete.
4.  When asked for **Review**, open the dialog.
5.  Verify the **Plan Details** (Version, Nodes).
6.  Click **Approve**.

---

## 🧹 Phase 5: Version Control Hygiene
We implemented a `.gitignore` to specifically exclude:
*   `.terraform/` folders (recursively).
*   `*.tfstate` and `*.tfvars` files containing secrets.
*   `tfplan` and `tfplan.json` artifacts.
