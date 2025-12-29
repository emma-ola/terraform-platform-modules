locals {
  # When creating: allow project_id to be supplied, otherwise derive from project_name.
  effective_project_id = (
    var.create_project
    ? coalesce(var.project_id, replace(lower(var.project_name), "/[^a-z0-9-]/", "-"))
    : var.project_id
  )
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
  # If we created a folder, use it otherwise use provided folder_id (may be null).
  effective_folder_id = var.create_folder ? google_folder.this[0].name : var.folder_id

  # if folder is set, project parent is the folder. Otherwise parent is the org.
  use_folder_parent = local.effective_folder_id != null
  effective_org_id  = local.use_folder_parent ? null : var.org_id
}

locals {
  # Ensure Service Usage is enabled first; enable the rest afterward.
  serviceusage_api = "serviceusage.googleapis.com"
  apis_set         = toset(var.activate_apis)
  other_apis_set   = setsubtract(local.apis_set, toset([local.serviceusage_api]))
}

locals {
  creating_requires = var.create_project ? (
    var.project_name != null &&
    var.billing_account != null &&
    local.effective_project_id != null &&
    (var.org_id != null || local.effective_folder_id != null) # Either org_id is provided (no folder) OR folder is provided/created
  ) : true
}

resource "google_project" "this" {
  count           = var.create_project ? 1 : 0
  project_id      = local.effective_project_id
  name            = var.project_name
  org_id          = local.effective_org_id
  folder_id       = local.use_folder_parent ? local.effective_folder_id : null
  labels          = var.labels
  billing_account = var.billing_account

  lifecycle {
    precondition {
      condition     = local.creating_requires
      error_message = "When create_project=true you must set project_name and billing_account, and provide either org_id (if no folder is used) or folder_id/create_folder."
    }
    precondition {
      condition     = (!var.create_folder) || var.create_project
      error_message = "create_folder=true requires create_project=true (otherwise the module would create a folder but no project)."
    }
  }
}


resource "google_project_service" "serviceusage" {
  count              = contains(var.activate_apis, local.serviceusage_api) ? 1 : 0
  project            = var.create_project ? google_project.this[0].project_id : var.project_id
  service            = local.serviceusage_api
  disable_on_destroy = false

  lifecycle {
    precondition {
      condition     = var.create_project || var.project_id != null
      error_message = "When create_project=false you must provide project_id so APIs can be enabled."
    }
  }
}

resource "google_project_service" "apis" {
  for_each           = local.other_apis_set
  project            = var.create_project ? google_project.this[0].project_id : var.project_id
  service            = each.value
  disable_on_destroy = false

  depends_on = [
    google_project_service.serviceusage
  ]

  lifecycle {
    precondition {
      condition     = var.create_project || var.project_id != null
      error_message = "When create_project=false you must provide project_id so APIs can be enabled."
    }

    precondition {
      condition = (!var.create_project) || (
        var.project_name != null &&
        var.billing_account != null &&
        (
          var.org_id != null || local.effective_folder_id != null
        )
      )
      error_message = "When create_project=true you must set project_name and billing_account, and provide either org_id (if no folder is used) or folder_id/create_folder."
    }


    precondition {
      condition     = (!var.create_folder) || (var.create_project && var.folder_display_name != null && var.folder_parent != null)
      error_message = "When create_folder=true you must set create_project=true and provide folder_display_name and folder_parent."
    }
  }
}
