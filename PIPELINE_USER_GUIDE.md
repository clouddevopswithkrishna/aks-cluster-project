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

### Method A: Manual Run (Ad-hoc)
Use this to destroy the cluster interactively.

1.  Go to Azure DevOps Pipelines -> Click "Run Pipeline".
2.  Select Branch: `main` (Only main can Apply/Destroy).
3.  **Check the box**: "Destroy Infrastructure?".
4.  **Review**: The Warning and Plan will appear in the Manual Review step.
5.  **Approve**: Clicking approved triggers the destruction.

### Method B: Via Pull Request (The "GitOps" Way)
To destroy via PR (without the checkbox), you must verify the destruction by deleting the code.

1.  **Delete Code**: In a branch, delete the module block for `aks_cluster` in `main.tf`.
2.  **Raise PR**: The pipeline will see code is missing and plan a destroy.
3.  **Merge**: Merging to main triggers the actual destruction.

---

## 3. Important Rules

*   **Main Branch Only**: The `Apply` stage (Deploy/Destroy) ONLY runs on the `main` branch.
*   **Feature Branches**: Running the pipeline on any other branch will **Skip Apply** (Plan Only).
*   **Variables**: All variables (Cluster Name, etc.) are read from `terraform.tfvars`.
*   **Branch Protection**: Don't forget to enable Branch Policies!
