module "project" {
  source = "../../modules/project"

  # Existing project mode
  create_project = false
  project_id     = var.project_id
  labels         = var.labels
}
