# Project Module

Bootstraps a **Google Cloud project** as a foundational platform primitive.

This module is intended for platform and infrastructure teams that want
consistent project creation, billing attachment, API enablement, and labeling
across environments.

---

## Modes of operation

### Existing project mode (default)
- Set `project_id`
- No project is created
- Required APIs are enabled on the existing project

### Create project mode
- Set `create_project = true`
- Creates a new project under an organization or folder
- Attaches a billing account
- Enables required APIs

---

## What this module does

- Optionally creates a GCP project
- Places the project under an organization or folder
- Attaches a billing account (when creating)
- Enables a standard list of required APIs
- Enforces required project labels:
    - `env`
    - `owner`
    - `cost_center`

---

## What this module does NOT do

- Create networking resources
- Manage IAM beyond basic project ownership
- Deploy workloads or services

Those concerns are intentionally handled by other platform modules.

---

## Usage

### Create a project under an organization

```hcl
module "project" {
  source = "../../modules/project"

  create_project  = true
  project_name    = "platform-staging-01"
  project_id      = "platform-staging-01"
  org_id          = "123456789012"
  billing_account = "01D95F-F2738E"

  labels = {
    env         = "staging"
    owner       = "platform"
    cost_center = "shared"
  }
}
```

### Create a project under a folder

```hcl
module "project" {
source = "../../modules/project"

create_project  = true
project_name    = "platform-prod-01"
project_id      = "platform-prod-01"
folder_id       = "folders/456789012345"
billing_account = "01D95F-F2738E"

labels = {
env         = "prod"
owner       = "platform"
cost_center = "shared"
  }
}
```

### Reference an existing project

```hcl
module "project" {
  source = "../../modules/project"

  create_project = false
  project_id     = "existing-project-id"
}
```

### Validation and guardrails

This module enforces:
- `billing_account` is required when creating a project
  - Exactly one of `org_id` or `folder_id` must be set when creating
- Folder creation cannot occur without project creation
- Invalid combinations fail fast during `terraform plan`

These validations are intentional and prevent orphaned or misconfigured projects.

## Outputs

Common outputs include:

- `project_id`
- `enabled_apis`
- `folder_id`

## Design notes
- Project creation is optional to support both greenfield and brownfield usage
- Labels are enforced to support cost allocation and ownership tracking
- This module is designed to be composed with network, IAM, and GKE modules
