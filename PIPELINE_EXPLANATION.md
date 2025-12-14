# Pipeline Configuration Explained
This document provides a detailed breakdown of the `azure-pipelines.yml` file used for the AKS Cluster project.

## 1. Trigger
```yaml
trigger:
  - main
```
*   **Purpose**: Defines when the pipeline runs automatically.
*   **Logic**: Monitoring the `main` branch. Any commit pushed to `main` triggers a run.

## 2. Parameters
Runtime inputs you can set when manually queuing the pipeline.
```yaml
parameters:
  - name: environment
    default: dev
    values: [dev, test, prod]
  - name: terraformDestroy
    type: boolean
    default: false
```
*   **environment**: Selects which environment folder (dev/test/prod) Terraform should run against.
*   **terraformDestroy**: A checkbox. If checked (`true`), the pipeline switches to "Destroy Mode" to delete the infrastructure.

## 3. Variables
Dynamic values used throughout the pipeline.
```yaml
variables:
  serviceConnection: 'azure-connection-name'  # The valid AZ service connection in ADO
  storageAccount: 'tfstateunique281012345'    # Azure Storage Account for TF State
  container: '${{ parameters.environment }}-tfstateunique12345' # Dynamic container name (e.g., dev-tfstate...)
  key: '${{ parameters.environment }}.terraform.tfstate'        # Stat file name
  
  # Logic to set the destroy flag based on the Checkbox parameter
  ${{ if eq(parameters.terraformDestroy, true) }}:
    destroyFlag: '-destroy'  # Adds -destroy to the plan command
  ${{ else }}:
    destroyFlag: ''          # Empty for normal deployment
```

## 4. Stages

### Stage 1: Validate
**Goal**: Check code quality before doing anything real.
*   **Lint Job**: Runs `terraform fmt -check` to ensure code style compliance.
*   **Validate Job**: Runs `terraform validate`.
    *   *Note*: Uses `terraform init -backend=false` because validation doesn't need the remote state to check syntax.

### Stage 2: Plan
**Goal**: Calculate what Terraform *would* do.
*   **Terraform Init**: Connects to the real Azure Backend (Storage Account) using the Service Connection.
*   **Terraform Plan**:
    *   Command: `terraform plan -out=tfplan -no-color $(destroyFlag)`
    *   `no-color`: Ensures logs are clean plain text.
    *   `$(destroyFlag)`: Injects `-destroy` if you checked the box.
    *   `-out=tfplan`: Saves the plan to a file.
*   **Analyze Plan (Script)**:
    *   `terraform show ... | perl ...`: Reads the plan and strips hidden "ANSI" color characters so it looks clean in the popup.
    *   **Warning Logic**: If `destroyFlag` is set, it creates a `⚠️ WARNING` message.
    *   **Output**: Saves the text to a variable `PlanDetails` to show in the next stage.
*   **Publish**: Uploads the `tfplan` file as an artifact so the specific plan can be used later.

### Stage 3: Review
**Goal**: Pause and ask for human approval.
*   **ManualValidation Task**:
    *   Pauses the pipeline.
    *   Sends an email to `user@example.com` (configurable).
    *   Displays the `PlanDetails` (from the previous stage) in the Azure DevOps UI.
    *   You must click "Resume" (Approve) or "Reject".

### Stage 4: Apply
**Goal**: Execute the changes.
*   **Condition**: 
    `and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'), ne(variables['Build.Reason'], 'PullRequest'))`
    *   **Safety Rule**: This stage ONLY runs if:
        1.  Previous stages passed.
        2.  You are on the **Main Branch**.
        3.  This is **NOT** a Pull Request.
*   **Steps**:
    1.  **Download**: Gets the `tfplan` artifact from the Plan stage.
    2.  **Show Plan**: Prints the plan again for final verification in logs.
    3.  **Terraform Apply**: Runs `terraform apply tfplan`. exact execution of the file generated in the Plan stage.
