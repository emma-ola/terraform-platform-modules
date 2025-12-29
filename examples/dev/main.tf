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
  network_name = "platform-vpc"
  subnets = {
    apps_us_central1 = {
      name          = "apps-us-central1"
      region        = var.region
      ip_cidr_range = "10.10.0.0/20"

      secondary_ranges = {
        pods = {
          range_name    = "pods"
          ip_cidr_range = "10.20.0.0/16"
        }
        services = {
          range_name    = "services"
          ip_cidr_range = "10.30.0.0/20"
        }
      }
    }

    shared_us_east1 = {
      name          = "shared-us-east1"
      region        = "us-east1"
      ip_cidr_range = "10.40.0.0/20"
    }
  }
}
