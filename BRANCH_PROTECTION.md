# How to "Freeze" the Main Branch (Branch Policies)

To prevent anyone (including yourself!) from pushing changes directly to `main`, you need to enable **Branch Policies** in Azure DevOps. This forces everyone to use a **Pull Request (PR)** workflow.

## Step 1: Go to Branch Policies
1.  Open your Azure DevOps Project.
2.  Navigate to **Repos** -> **Branches**.
3.  Find the `main` branch in the list.
4.  Hover over the row, click the **three dots (... )** on the right.
5.  Select **Branch policies**.

## Step 2: Enable Protections
On the policy page, turn **ON** the following settings:

### 1. Require a minimum number of reviewers
*   **Toggle**: On
*   **Minimum number of reviewers**: `1` (or 2 for stricter control).
*   *Effect: You cannot merge a PR until someone else approves it.*

### 2. Check for linked work items (Optional)
*   **Toggle**: On
*   *Effect: Forces every PR to be linked to a Ticket/User Story (good for tracking).*

### 3. Build Validation (CRITICAL for Terraform)
This ensures your pipeline runs (Terraform Plan) *before* the code merges.
1.  Click **+ Add build policy**.
2.  **Build pipeline**: Select your pipeline (e.g., `aks-cluster-project`).
3.  **Trigger**: Automatic.
4.  **Policy requirement**: Required.
5.  **Display name**: `Terraform Validation`.
6.  Click **Save**.

*Effect: If your Terraform Config is broken, the PR is blocked!*

## Step 3: Automatically Include Reviewers (Optional)
If you want specific people (like Tech Leads) to always be added:
1.  Find **Automatically included reviewers**.
2.  Click **+ Add automatic reviewers**.
3.  Search for the user or group.
4.  **Required**: Select "Required" if their approval is mandatory.
5.  Click **Save**.

---

## 🛑 How to work now?
Now, if you try to `git push origin main`, it will fail with an error like:
> `TF402455: Pushes to this branch are not permitted; you must use a pull request to update this branch.`

**New Workflow:**
1.  Create a branch: `git checkout -b feature/my-new-change`
2.  Make changes, commit, and push: `git push origin feature/my-new-change`
3.  Go to Azure DevOps -> **Repos** -> **Pull Requests**.
4.  Click **New Pull Request**.
5.  Wait for the "Build Validation" (Terraform Plan) to pass.
6.  Get approval.
7.  Click **Complete**.
