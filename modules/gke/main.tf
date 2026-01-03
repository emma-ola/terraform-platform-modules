resource "google_container_cluster" "this" {
  name                     = var.name
  project                  = var.project_id
  location                 = var.location
  remove_default_node_pool = true
  initial_node_count       = 1
  # Added because of quota limits on some GCP projects
  node_config {
    disk_size_gb = 40
  }
  deletion_protection      = var.deletion_protection
  network                  = var.network_self_link
  subnetwork               = var.subnetwork_self_link

  ip_allocation_policy {
    cluster_secondary_range_name  = var.ip_range_pods
    services_secondary_range_name = var.ip_range_services
  }

  release_channel {
    channel = var.release_channel
  }

  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  dynamic "private_cluster_config" {
    for_each = var.private_cluster ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = var.enable_private_endpoint ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = try(cidr_blocks.value.display_name, null)
        }
      }
    }
  }

  # Logging/Monitoring: keep defaults for now; we can make these configurable later
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  lifecycle {
    precondition {
      condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
      error_message = "release_channel must be RAPID, REGULAR, or STABLE."
    }

    precondition {
      condition     = !var.private_cluster || can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+\\/28$", var.master_ipv4_cidr_block))
      error_message = "When private_cluster=true, master_ipv4_cidr_block must be a /28 CIDR (e.g. 172.16.0.0/28)."
    }

    precondition {
      condition     = var.regional ? !can(regex("^[a-z]+-[a-z0-9]+\\d-[a-z]$", var.location)) : can(regex("^[a-z]+-[a-z0-9]+\\d-[a-z]$", var.location))
      error_message = "regional=true requires a region (e.g. us-central1). regional=false requires a zone (e.g. us-central1-a)."
    }

    precondition {
      condition     = !var.enable_private_endpoint || length(var.master_authorized_networks) > 0
      error_message = "When enable_private_endpoint=true, you must provide master_authorized_networks (at least one CIDR) to avoid locking yourself out."
    }
  }
}
