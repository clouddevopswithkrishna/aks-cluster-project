# AKS Pipeline User Guide

This pipeline automates the lifecycle of your AKS cluster on Azure.

## 1. Normal Usage (Deploy/Update)

### How to use:
1.  **Edit Code**: Modify your Terraform files (e.g., change node count in `main.tf` or `terraform.tfvars`).
2.  **Raise PR**: Create a branch and raise a Pull Request targetting `main`.
3.  **PR Check**: The pipeline runs automatically.
    *   It Validates and Plans.
    *   In "Manual Review", it shows you the Plan details.
    *   *Note: PRs will NEVER Apply changes.*
4.  **Merge**: Once PR is approved, merge to `main`.
5.  **Deploy**: The `main` branch pipeline runs automatically.
    *   It Plans -> Shows Manual Review -> waits for your Approval -> Applies Changes.

---

## 2. How to Destroy the Cluster

### Method A: Via Pull Request (The "Safe" Way)
Use this when you want an audit trail of the destruction.

1.  **Create Trigger**: In your environment folder (e.g., `environments/dev`), create a **new empty file** named `DESTROY_TRIGGER`.
2.  **Raise PR**: Push and raise a PR with this file.
3.  **Review**: The pipeline will detect the file and run `terraform plan -destroy`.
    *   The Manual Review screen will show: `⚠️⚠️⚠️ WARNING: CLUSTER WILL BE DESTROYED ⚠️⚠️⚠️`.
4.  **Merge**: Approve and merge the PR.
5.  **Execute**: The `main` branch pipeline will run and **Destroy** the cluster.

> **To Restore**: Raise a new PR that **deletes** the `DESTROY_TRIGGER` file. The pipeline will then switch back to Normal Mode and re-create the cluster on the next run.

### Method B: Manual Run (Ad-hoc)
1.  Go to Azure DevOps Pipelines -> Click "Run Pipeline".
2.  (Note: we removed the checkbox to support automation, so Method A is preferred. If you really need manual run without file, you must edit `terraform.tfvars` locally first).

---

## 3. Important Notes

*   **Variables**: All variables (Cluster Name, etc.) are read from `terraform.tfvars` in the repo.
*   **Branch Protection**: You MUST configure Azure DevOps Branch Policies to prevent direct pushes to `main`. (See `BRANCH_PROTECTION.md`).
*   **Environment Gate**: The "Post-deployment" Manual Validation in Azure (the second pop-up) is optional. We recommend disabling it since our pipeline has its own "Manual Review" step with better details.
