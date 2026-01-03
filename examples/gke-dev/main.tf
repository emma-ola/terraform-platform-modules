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
  subnets = {
    gke_us_central1 = {
      name          = "gke-us-central1"
      region        = var.region
      ip_cidr_range = "10.10.0.0/16"
      flow_logs = {
        enabled              = true
        aggregation_interval = "INTERVAL_10_MIN"
      }
      secondary_ranges = {
        pods = {
          range_name    = "pods"
          ip_cidr_range = "10.20.1.0/24"
        }
        svc = {
          range_name    = "services"
          ip_cidr_range = "10.30.1.0/24"
        }
      }
    }
  }
  nat = {
    enabled = false
    regions = {
      (var.region) = {
        source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_PRIMARY_IP_RANGES"
      }
    }
  }
}

module "gke" {
  source = "../../modules/gke"

  project_id           = var.project_id
  name                 = "platform-dev"
  location             = var.region
  regional             = true
  network_self_link    = module.network.network_id
  subnetwork_self_link = module.network.subnet_self_links["gke_us_central1"]
  ip_range_pods        = "pods"
  ip_range_services    = "svc"
  node_pools = {
    default = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
      disk_size_gb = 50
    }
  }
}
