# project module

Bootstraps a GCP project for platform use.

## Modes
- **Existing project mode (default):** set `project_id`, enable required APIs.
- **Create project mode:** set `create_project=true` plus org/billing inputs.

## What it does
- (Optional) creates a project and attaches billing
- enables a standard list of APIs
- enforces required labels: `env`, `owner`, `cost_center`

