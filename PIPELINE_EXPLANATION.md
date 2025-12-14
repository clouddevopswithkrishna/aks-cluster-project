# Azure Pipeline Configuration - Detailed Explanation

This document provides a comprehensive, line-by-line breakdown of the `azure-pipelines.yml` file.

## Trigger
```yaml
trigger:
  - main
```
*   **`trigger`**: Defines the CI (Continuous Integration) trigger rules.
*   **`- main`**: The pipeline will automatically start whenever code is pushed to the `main` branch.

## Parameters
Parameters allow you to provide input when manually triggering the pipeline.
```yaml
parameters:
  - name: environment
    displayName: Target Environment
    type: string
    default: dev
    values:
      - dev
      - test
      - prod
```
*   **`name: environment`**: Internal variable name `params.environment`.
*   **`displayName`**: The label shown in the Azure DevOps UI (e.g., "Target Environment").
*   **`values`**: Dropdown list restrictions. You can only pick `dev`, `test`, or `prod`.

```yaml
  - name: terraformDestroy
    displayName: 'Destroy Infrastructure?'
    type: boolean
    default: false
```
*   **`name: terraformDestroy`**: Boolean switch (Checkbox).
*   **`default: false`**: Unchecked by default for safety. If checked (`true`), checking this box intends to destroy resources.

## Build Agent Pool
```yaml
pool:
  vmImage: 'ubuntu-latest'
```
*   **`pool`**: Specifies the build agent infrastructure.
*   **`vmImage`**: Uses a Microsoft-hosted Ubuntu Linux agent.

## Variables
```yaml
variables:
  serviceConnection: 'azure-connection-name'
```
*   **`serviceConnection`**: The name of the Service Connection in Azure DevOps Project Settings used to authenticate with Azure.

```yaml
  resourceGroup: 'terraform-state-rg'
  storageAccount: 'tfstateunique281012345'
  container: '${{ parameters.environment }}-tfstateunique12345'
  key: '${{ parameters.environment }}.terraform.tfstate'
```
*   **`storageAccount`**: The Azure Storage Account where Terraform state is stored.
*   **`container`**: Dynamically names the container based on the environment (e.g., `dev-tfstate...`).
*   **`key`**: The specific state file name (e.g., `dev.terraform.tfstate`).

```yaml
  environment: ${{ parameters.environment }}
```
*   **`environment`**: Maps the parameter value to a pipeline variable `$(environment)` for easier use in tasks.

### Conditional Variable Logic
```yaml
  ${{ if eq(parameters.terraformDestroy, true) }}:
    destroyFlag: '-destroy'
  ${{ else }}:
    destroyFlag: ''
```
*   **Logic**: Checks if the "Destroy Infrastructure?" checkbox was ticked.
*   **`destroyFlag: '-destroy'`**: If true, sets this variable to `-destroy`. This string is later passed to the `terraform plan` command.
*   **`destroyFlag: ''`**: If false, keeps it empty (Normal Plan).

---

## Stages

### Stage 1: Validate
```yaml
stages:
  - stage: Validate
    displayName: 'Validation & Linting'
```
*   **Purpose**: Validates code syntax and style before any remote connection.

#### Job: Lint
```yaml
      - job: Lint
        steps:
          - task: TerraformInstaller@0
            inputs:
              terraformVersion: 'latest'
          - script: terraform fmt -check -recursive
```
*   **`terraform fmt -check`**: Checks if code is properly formatted (canonical format). Fails if code is messy.

#### Job: Validate
```yaml
      - job: Validate
        dependsOn: Lint
        steps:
          - script: |
              terraform init -backend=false
              terraform validate
            workingDirectory: '$(System.DefaultWorkingDirectory)/environments/$(environment)'
```
*   **`dependsOn: Lint`**: Waits for Lint to pass.
*   **`init -backend=false`**: Initializes Terraform locally without connecting to Azure (faster/safer for just validation).
*   **`validate`**: Checks for syntax errors and valid argument references.

### Stage 2: Plan
```yaml
  - stage: Plan
    jobs:
      - job: Plan
        steps:
```

#### Step: Terraform Init (Real)
```yaml
          - task: TerraformTaskV4@4
            inputs:
              command: 'init'
              backendServiceArm: '$(serviceConnection)'
              ...
```
*   **`TerraformTaskV4`**: Official Microsoft task for Terraform.
*   **`command: 'init'`**: Initializes the backend, downloading the state from Azure Storage.

#### Step: Terraform Plan
```yaml
          - task: TerraformTaskV4@4
            inputs:
              command: 'plan'
              commandOptions: '-out=tfplan -no-color $(destroyFlag)'
              environmentServiceNameAzureRM: '$(serviceConnection)'
```
*   **`command: 'plan'`**: Generates an execution plan.
*   **`-out=tfplan`**: Saves the plan to a binary file `tfplan`.
*   **`-no-color`**: Disables color codes in logs for readability.
*   **`$(destroyFlag)`**: Injects `-destroy` if the checkbox was selected.

#### Step: Analyze Plan (Bash Script)
```yaml
          - script: |
              PLAN_TEXT=$(terraform show -no-color tfplan | perl -pe 's/\e\[?.*?[\@-~]//g')
```
*   **`terraform show`**: Converts the binary `tfplan` into readable text.
*   **`perl ...`**: A regex command to strip invisible ANSI color codes that Terraform might still output.

```yaml
              DETAILS="Target Environment: $(environment)"
              if [ "$(destroyFlag)" == "-destroy" ]; then
                 DETAILS+="⚠️⚠️⚠️ WARNING: CLUSTER WILL BE DESTROYED ⚠️⚠️⚠️"
              fi
```
*   **Logic**: If destroying, it prepends a generic Warning message to the details.

```yaml
              echo "##vso[task.setvariable variable=PlanDetails;isOutput=true]$DETAILS"
```
*   **`##vso` command**: A special log command that sets an Azure DevOps variable `PlanDetails` to be available in future stages.

#### Step: Publish Artifact
```yaml
          - publish: ...
            artifact: tfplan
```
*   **Purpose**: Uploads the `tfplan` file so the *Apply* stage can download and use the exact same plan later.

### Stage 3: Review
```yaml
  - stage: Review
    jobs:
      - job: WaitForValidation
        pool: server
```
*   **`pool: server`**: Runs on the Azure DevOps server (agentless), not an agent machine. Used for waiting/approvals.

#### Step: Manual Validation
```yaml
          - task: ManualValidation@0
            inputs:
              instructions: |
                Changes Detected:
                $(PlanDetails)
```
*   **`ManualValidation`**: Pauses the pipeline execution.
*   **`$(PlanDetails)`**: Displays the text captured in the previous stage for human review.

### Stage 4: Apply
```yaml
  - stage: Apply
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'), ne(variables['Build.Reason'], 'PullRequest'))
```
*   **`condition`**: Critical safety logic. The job ONLY runs if:
    1.  **`succeeded()`**: Previous stages passed.
    2.  **`eq(main)`**: The branch is exactly `main`.
    3.  **`ne(PullRequest)`**: This is NOT a Pull Request build.

#### Job: Deployment
```yaml
      - deployment: Apply
        environment: ${{ parameters.environment }}
```
*   **`deployment`**: A special job type that tracks "Deployments" in ADO Environments.

#### Step: Terraform Apply
```yaml
                - task: TerraformTaskV4@4
                  inputs:
                    command: 'apply'
                    commandOptions: '$(Pipeline.Workspace)/tfplan/tfplan'
```
*   **`command: 'apply'`**: Applies the changes.
*   **`commandOptions`**: Points to the downloaded `tfplan` artifact. This ensures we apply *exactly* what was reviewed, with no new calculation.
