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
          ip_cidr_range = "10.20.0.0/16"
        }
        svc = {
          range_name    = "svc"
          ip_cidr_range = "10.30.0.0/16"
        }
      }
    }
  }
  nat = {
    enabled = false
  }
}

module "gke" {
  source = "../../modules/gke"

  project_id           = module.project.project_id
  name                 = "platform-dev"
  location             = var.region
  regional             = true
  network_self_link    = module.network.network_id
  subnetwork_self_link = module.network.subnet_self_links["gke_us_central1"]
  ip_range_pods        = "pods"
  ip_range_services    = "svc"
  master_authorized_networks = [
    {
      cidr_block   = "10.10.0.0/16"
      display_name = "gke-subnet"
    }
  ]
  node_pools = {
    default = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
      disk_size_gb = 20
      labels = {
        pool = "default"
      }
    }
    spot = {
      machine_type        = "e2-standard-4"
      autoscaling_enabled = false
      min_count           = 0
      max_count           = 0
      node_count          = 2
      spot                = true
      disk_size_gb        = 20
      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]
      labels = {
        pool = "spot"
      }
    }
  }
}
