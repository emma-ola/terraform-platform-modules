module "project" {
  source = "../../modules/project"

  create_project      = true
  create_folder       = true
  folder_display_name = var.folder_display_name
  folder_parent       = var.folder_parent
  project_name        = var.project_name
  project_id          = var.project_id
  billing_account     = var.billing_account
  labels              = var.labels
}

module "network" {
  source = "../../modules/network"

  project_id   = module.project.project_id
  network_name = "platform-gke-vpc"
  subnets      = {}
  nat = {
    enabled = false
    regions = {
      (var.region) = {
        source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
      }
    }
  }
}
