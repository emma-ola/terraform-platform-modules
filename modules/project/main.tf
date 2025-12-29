locals {
  # When creating: allow project_id to be supplied, otherwise derive from project_name.
  effective_project_id = var.create_project
    ? coalesce(var.project_id, replace(lower(var.project_name), "/[^a-z0-9-]/", "-"))
    : var.project_id
}

resource "google_folder" "this" {
  count        = var.create_folder ? 1 : 0
  display_name = var.folder_display_name
  parent       = var.folder_parent

  lifecycle {
    precondition {
      condition     = var.folder_display_name != null && var.folder_parent != null
      error_message = "When create_folder=true you must set folder_display_name and folder_parent."
    }
  }
}

locals {
  # If we created a folder, use it; otherwise use the caller-provided folder_id (may be null).
  effective_folder_id = var.create_folder ? google_folder.this[0].name : var.folder_id
}

locals {
  creating_requires = var.create_project ? (
  var.project_name != null &&
  var.org_id != null &&
  var.billing_account != null &&
  local.effective_project_id != null
  ) : true
}

resource "google_project" "this" {
  count      = var.create_project ? 1 : 0
  project_id = local.effective_project_id
  name       = var.project_name
  org_id     = var.org_id
  folder_id  = local.effective_folder_id
  labels     = var.labels

  lifecycle {
    precondition {
      condition     = local.creating_requires
      error_message = "When create_project=true you must set project_name, org_id, billing_account, and provide project_id or a project_name that can be converted into one."
    }
    precondition {
      condition     = (!var.create_folder) || var.create_project
      error_message = "create_folder=true requires create_project=true (otherwise the module would create a folder but no project)."
    }
  }
}

resource "google_project_billing_info" "this" {
  count           = var.create_project ? 1 : 0
  project         = google_project.this[0].project_id
  billing_account = var.billing_account
}

resource "google_project_service" "apis" {
  for_each           = toset(var.activate_apis)
  project            = var.create_project ? google_project.this[0].project_id : var.project_id
  service            = each.value
  disable_on_destroy = false

  lifecycle {
    precondition {
      condition     = var.create_project || var.project_id != null
      error_message = "When create_project=false you must provide project_id so APIs can be enabled."
    }
  }
}
