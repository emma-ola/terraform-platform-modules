output "project_id" {
  description = "The project ID used/created by this module."
  value       = var.create_project ? google_project.this[0].project_id : var.project_id
}

output "enabled_apis" {
  description = "APIs enabled by this module."
  value       = sort([for s in google_project_service.apis : s.service])
}

output "folder_id" {
  description = "Folder resource name used for the project (e.g., folders/123...). Null if no folder was used."
  value       = local.effective_folder_id
}
