/* =========================================================
   PROJECT MODULE INPUTS
   - Designed for adoption: existing project by default
   - Optional: create folder + create project
   ========================================================= */

# Mode
variable "create_project" {
  description = "If true, create a new GCP project. If false, use an existing project_id."
  type        = bool
  default     = false
}

# Existing project mode
variable "project_id" {
  description = "Existing project ID to use when create_project=false. Also used as the ID when create_project=true unless project_id is null."
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id must look like a valid GCP project id (lowercase, 6-30 chars, starts with a letter, only a-z 0-9 and hyphen)."
  }
}

# Project creation mode
variable "project_name" {
  description = "Human-friendly project name. Required when create_project=true."
  type        = string
  default     = null
}

variable "org_id" {
  description = "GCP Organization ID. Required when create_project=true unless using folder_parent under the org."
  type        = string
  default     = null
}

variable "billing_account" {
  description = "Billing account ID. Required when create_project=true."
  type        = string
  default     = null
}

# Folder placement
variable "folder_id" {
  description = "Existing folder resource name to place the project under (e.g., folders/123). Optional."
  type        = string
  default     = null

  validation {
    condition     = var.folder_id == null || can(regex("^folders/[0-9]+$", var.folder_id))
    error_message = "folder_id must be in the form folders/1234567890."
  }
}

variable "create_folder" {
  description = "If true, create a new folder and (if creating a project) place the project inside it."
  type        = bool
  default     = false
}

variable "folder_display_name" {
  description = "Display name for the folder to create. Required when create_folder=true."
  type        = string
  default     = null
}

variable "folder_parent" {
  description = "Parent resource for the folder. Example: organizations/123 or folders/456. Required when create_folder=true."
  type        = string
  default     = null

  validation {
    condition     = var.folder_parent == null || can(regex("^(organizations|folders)/[0-9]+$", var.folder_parent))
    error_message = "folder_parent must be in the form organizations/1234567890 or folders/1234567890."
  }
}

# Governance (labels)
variable "labels" {
  description = "Labels applied to the project (and used by downstream modules). Must include env, owner, cost_center."
  type        = map(string)
  default     = {}

  validation {
    condition = (
      contains(keys(var.labels), "env") &&
      contains(keys(var.labels), "owner") &&
      contains(keys(var.labels), "cost_center")
    )
    error_message = "labels must include: env, owner, cost_center."
  }
}

variable "activate_apis" {
  description = "List of GCP APIs to enable in the project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}
