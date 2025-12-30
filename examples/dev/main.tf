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
  manage_firewall_rules = true
  firewall_rules = {
    allow_internal_to_app = {
      name        = "allow-internal-to-app"
      description = "Allow internal RFC1918 to app instances via target tag"
      direction   = "INGRESS"
      priority    = 1000

      source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
      target_tags   = ["app"]

      allows = [
        { protocol = "tcp", ports = ["8080"] },
        { protocol = "icmp" }
      ]

      enable_logging = true
    }

    allow_ops_sa_to_admin_sa = {
      name        = "allow-ops-sa-to-admin-sa"
      description = "Allow ops VMs (by SA) to reach admin VMs (by SA) on SSH"
      direction   = "INGRESS"
      priority    = 900

      source_service_accounts = [
        "ops-bastion@${var.project_id}.iam.gserviceaccount.com"
      ]

      target_service_accounts = [
        "admin@${var.project_id}.iam.gserviceaccount.com"
      ]

      allows = [
        { protocol = "tcp", ports = ["22"] }
      ]

      enable_logging = false
    }

    allow_tools_tag_to_db_tag = {
      name        = "allow-tools-to-db"
      description = "Allow instances with 'tools' tag to reach 'db' tag on 5432"
      direction   = "INGRESS"
      priority    = 950

      source_tags = ["tools"]
      target_tags = ["db"]

      allows = [
        { protocol = "tcp", ports = ["5432"] }
      ]

      enable_logging = false
    }

    egress_to_internet_https = {
      name        = "egress-to-internet-https"
      description = "Allow outbound HTTPS to the internet"
      direction   = "EGRESS"
      priority    = 1000

      destination_ranges = ["0.0.0.0/0"]

      allows = [
        { protocol = "tcp", ports = ["443"] }
      ]

      enable_logging = false
    }

    deny_all_ingress_to_sensitive = {
      name        = "deny-all-to-sensitive"
      description = "Deny all ingress from the internet to sensitive workloads"
      direction   = "INGRESS"
      priority    = 800

      source_ranges = ["0.0.0.0/0"]
      target_tags   = ["sensitive"]

      denies = [
        { protocol = "all" }
      ]

      enable_logging = true
    }
  }
}
