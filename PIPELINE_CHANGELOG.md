# Pipeline Change Log

## 1. Authentication Fix
*   **Issue**: `terraform init` failed with "unable to build authorizer" because the bash script lacked credentials.
*   **Fix**: Replaced the script with the **Azure DevOps Terraform Task (`TerraformTaskV4`)**. This task uses the Service Connection (`backendServiceArm`) to natively authenticate.

## 2. Remote Backend Fix
*   **Issue**: Pipeline was pointing to a non-existent storage account (`tfstateunique12345`).
*   **Fix**: Updated `azure-pipelines.yml` to use `devtfstateunique12345` (and eventually `tfstateunique281012345`).
*   **Fix**: Added empty `backend "azurerm" {}` block to `main.tf` to allow partial configuration from the pipeline.

## 3. Variable Handling (Fixing the Hang)
*   **Issue**: `terraform.tfvars` was gitignored, causing the pipeline to prompt for input and hang.
*   **Fix**: Removed `*.tfvars` from `.gitignore`. This allows `terraform.tfvars` to be committed, so the pipeline reads values automatically.

## 4. Full Plan Visibility
*   **Feature**: User requested to see the full Terraform Plan in the review screen.
*   **Change**: Updated `azure-pipelines.yml` to capture `terraform show` output and display it in the **"Manual Review"** step instructions.
*   **Change**: Added a `Show Plan` script step to the **Apply Stage** logs for double-verification.

## 5. PR Support
*   **Feature**: Users want to use Pull Requests (PRs) to validate changes.
*   **Change**: Removed manual "Run Parameters" that break automated PRs.
*   **Change**: Added logic to **Skip Apply** on PR builds (`condition: ne(variables['Build.Reason'], 'PullRequest')`). PRs only Plan/Validate.

## 6. Destroy Workflow (Marker File)
*   **Feature**: Ability to destroy cluster via PR without deleting Terraform code.
*   **Change**: Implemented "Trigger File" logic. If a file named `DESTROY_TRIGGER` exists in the environment folder:
    *   Terraform runs with `-destroy` flag.
    *   Manual Review shows a **BIG RED WARNING**.
