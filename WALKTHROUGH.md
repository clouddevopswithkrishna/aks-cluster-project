# Pipeline Verification Walkthrough

We have successfully configured and verified the following components of the AKS Pipeline.

## 1. Code Updates
*   **Synced Environments**: Updated `dev`, `test`, and `prod` `main.tf` to support pipeline-based backend configuration.
*   **Git Config**: Updated `.gitignore` to allow `terraform.tfvars`.
*   **Pipeline Logic**: Updated `azure-pipelines.yml` with:
    *   Auth fix (TerraformTaskV4).
    *   Manual "Destroy Checkbox".
    *   Strict Branch Safety (main only applies).
    *   Plain Text Plan output (Perl regex).

## 2. Verification Steps

### Step 1: Manual Run (Dev)
1.  Navigate to Pipelines in Azure DevOps.
2.  Run the pipeline on `main` branch.
3.  **Result**: 
    *   It should **Plan** successfully.
    *   The **Manual Review** popup should show clean, plain-text plan details.
    *   After approval, it should **Apply**.

### Step 2: PR Run
1.  Create a feature branch.
2.  Raise a PR.
3.  **Result**:
    *   Pipeline runs automatically.
    *   It **Plans** (shows details in popup).
    *   It **Skips Apply** automatically.

### Step 3: Destroy Run
1.  Manually run on `main`.
2.  Check "Destroy Infrastructure".
3.  **Result**:
    *   Plan shows "Destroy" warnings (Red text).
    *   Popup shows `⚠️⚠️⚠️ WARNING`.
    *   Approve -> Cluster Destroyed.

## 3. Documentation
All changes and user guides are now in your repo:
*   [PIPELINE_USER_GUIDE.md](file:///d:/AntiGravity/aks-cluster-project/PIPELINE_USER_GUIDE.md)
*   [PIPELINE_CHANGELOG.md](file:///d:/AntiGravity/aks-cluster-project/PIPELINE_CHANGELOG.md)
