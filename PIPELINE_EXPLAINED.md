# Azure Pipelines YAML Explained (`azure-pipelines.yml`)

This document provides a technical breakdown of each stage, job, and task within the CI/CD pipeline.

---

## 1. Parameters & Variables (Dynamic Configuration)

The pipeline starts by defining runtime inputs and dynamic variables to ensure environment isolation.

```yaml
parameters:
  - name: environment
    displayName: Target Environment
    type: string
    default: dev
    values: [dev, test, prod]
```
*   **Purpose**: Allows the user to select the target (`dev`, `test`, `prod`) when clicking "Run".
*   **Logic**: This value is passed into the pipeline as `${{ parameters.environment }}`.

```yaml
variables:
  key: '${{ parameters.environment }}.terraform.tfstate'
  environment: ${{ parameters.environment }}
```
*   **Dynamic State Key**: Automatically switches the backend file (e.g., `prod.terraform.tfstate`) based on the parameter.
*   **Environment Variable**: Makes the parameter available to all scripts as `$(environment)`.

---

## 2. Stage: Validate (Quality Control)

**Goal**: Fail fast if the code is messy or broken.

### Job: Lint
*   **Command**: `terraform fmt -check -recursive`
*   **Action**: Checks if all `.tf` files follow standard HCL formatting. Fails if files are not formatted.

### Job: Validate
*   **Command**: `terraform validate`
*   **Action**: checks for syntax errors and valid argument references.
*   **Note**: Runs `terraform init -backend=false` first because validation doesn't need the remote state.

---

## 3. Stage: Plan (Change Calculation)

**Goal**: Determine what *would* happen without actually changing anything.

### Job: Plan
1.  **Terraform Init (Remote)**:
    *   Connects to the Azure Storage Account using the dynamic variables (`resourceGroup`, `storageAccount`, `container`, `key`).
    *   Downloads provider plugins.
2.  **Terraform Plan**:
    *   Generates the execution plan.
    *   Saves the plan to a binary file: `tfplan`.
3.  **Analyze Plan (The "Smart" Logic)**:
    *   **Action**: Converts `tfplan` to JSON (`terraform show -json`).
    *   **Parsing**: Uses `jq` to filter the JSON for `azurerm_kubernetes_cluster` resources.
    *   **Extraction**: Grabs critical details: Version, Node Count, VM Size.
    *   **Output**: Sets a pipeline variable `PlanDetails` containing a human-readable summary of the changes. This is crucial for the manual review step.
4.  **Publish Artifact**:
    *   Uploads the `tfplan` binary so the **Apply** stage uses the *exact same plan* later.

---

## 4. Stage: Review (Manual Gate)

**Goal**: Pause execution and wait for human approval.

### Job: WaitForValidation
*   **Type**: Agentless Job (Runs on the server, not an agent).
*   **Task**: `ManualValidation@0`.
*   **Instructions**: dynamic text using `$(PlanDetails)`.
    *   **Effect**: The approval popup in Azure DevOps displays the summarized changes (e.g., "Upgrading to 1.32.3") directly in the UI.
*   **Timeout**: 1440 minutes (24 hours). If not approved by then, the run sends a "Reject" signal.

---

## 5. Stage: Apply (Deployment)

**Goal**: Execute the approved changes.

### Job: Apply
*   **Environment**: `${{ parameters.environment }}`
    *   **Why?**: This links the job to the ADO Environment (e.g., `prod`), enforcing any "Approvals and Checks" configured in the ADO UI.
*   **Strategy**: `runOnce` (Standard deployment).
*   **Steps**:
    1.  **Download Artifact**: Retrieves the `tfplan` binary from the Plan stage.
    2.  **Terraform Init**: Re-initializes the backend (required for Apply).
    3.  **Terraform Apply**:
        *   Command: `terraform apply ... tfplan`
        *   **Safety**: Uses the *pre-calculated plan* file. This ensures that exactly what was planned (and approved) is what gets executed. It will NEVER accidentally pick up new changes made while the pipeline was waiting.
