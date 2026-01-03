resource "google_container_cluster" "this" {
  name                     = var.name
  project                  = var.project_id
  location                 = var.location
  remove_default_node_pool = true
  initial_node_count       = 1
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

resource "google_container_node_pool" "this" {
  for_each = var.node_pools

  name       = "${var.name}-${each.key}"
  project    = var.project_id
  location   = var.location
  cluster    = google_container_cluster.this.name
  node_count = try(each.value.autoscaling_enabled, true) ? null : coalesce(try(each.value.node_count, null), each.value.min_count)

  dynamic "autoscaling" {
    for_each = try(each.value.autoscaling_enabled, true) ? [1] : []
    content {
      min_node_count = each.value.min_count
      max_node_count = each.value.max_count
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = try(each.value.disk_size_gb, 20)
    disk_type       = try(each.value.disk_type, "pd-balanced")
    oauth_scopes    = try(each.value.oauth_scopes, ["https://www.googleapis.com/auth/cloud-platform"])
    service_account = try(each.value.service_account, null)
    labels          = try(each.value.labels, {})
    tags            = length(try(each.value.tags, [])) > 0 ? each.value.tags : null
    spot            = try(each.value.spot, false)

    dynamic "taint" {
      for_each = try(each.value.taints, [])
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.min_count <= each.value.max_count
      error_message = "Node pool '${each.key}': min_count must be <= max_count."
    }

    precondition {
      condition = alltrue([
        for t in try(each.value.taints, []) :
        contains(["NO_SCHEDULE", "PREFER_NO_SCHEDULE", "NO_EXECUTE"], t.effect)
      ])
      error_message = "Node pool '${each.key}': taint.effect must be NO_SCHEDULE, PREFER_NO_SCHEDULE, or NO_EXECUTE."
    }

    precondition {
      condition     = try(each.value.autoscaling_enabled, true) || try(each.value.node_count, null) != null
      error_message = "Node pool '${each.key}': when autoscaling_enabled=false you must set node_count."
    }

    precondition {
      condition     = !try(each.value.autoscaling_enabled, true) || (each.value.min_count <= each.value.max_count)
      error_message = "Node pool '${each.key}': min_count must be <= max_count when autoscaling is enabled."
    }
  }
}
