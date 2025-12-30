resource "google_compute_network" "this" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  for_each      = var.subnets
  name          = each.value.name
  project       = var.project_id
  region        = each.value.region
  network       = google_compute_network.this.id
  ip_cidr_range = each.value.ip_cidr_range

  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

# noinspection HILUnresolvedReference
resource "google_compute_firewall" "rules" {
  for_each = var.manage_firewall_rules ? var.firewall_rules : {}

  name        = each.value.name
  project     = var.project_id
  network     = google_compute_network.this.name
  description = each.value.description
  direction   = each.value.direction
  priority    = each.value.priority
  disabled    = each.value.disabled
  target_tags = (
    each.value.direction == "INGRESS" &&
    length(each.value.target_tags) > 0 &&
    length(each.value.source_service_accounts) == 0
  ) ? each.value.target_tags : null
  target_service_accounts = length(each.value.target_service_accounts) > 0 ? each.value.target_service_accounts : null
  source_ranges           = each.value.direction == "INGRESS" && length(each.value.source_ranges) > 0 ? each.value.source_ranges : null
  source_tags             = each.value.direction == "INGRESS" && length(each.value.source_tags) > 0 ? each.value.source_tags : null
  source_service_accounts = each.value.direction == "INGRESS" && length(each.value.source_service_accounts) > 0 ? each.value.source_service_accounts : null
  destination_ranges      = each.value.direction == "EGRESS" && length(each.value.destination_ranges) > 0 ? each.value.destination_ranges : null

  dynamic "allow" {
    for_each = each.value.allows
    content {
      protocol = allow.value.protocol
      ports    = allow.value.ports
    }
  }

  dynamic "deny" {
    for_each = each.value.denies
    content {
      protocol = deny.value.protocol
      ports    = deny.value.ports
    }
  }

  log_config {
    metadata = each.value.enable_logging ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }

  lifecycle {
    precondition {
      condition     = !(length(each.value.allows) > 0 && length(each.value.denies) > 0)
      error_message = "Firewall rule '${each.key}' cannot have both allows and denies."
    }
    precondition {
      condition     = length(each.value.allows) > 0 || length(each.value.denies) > 0
      error_message = "Firewall rule '${each.key}': you must define at least one allow or deny block."
    }
    precondition {
      condition     = contains(["INGRESS", "EGRESS"], each.value.direction)
      error_message = "Firewall rule '${each.key}' direction must be INGRESS or EGRESS."
    }
    precondition {
      condition = !(each.value.direction == "EGRESS" && (
        length(each.value.source_ranges) > 0 ||
        length(each.value.source_tags) > 0 ||
        length(each.value.source_service_accounts) > 0
      ))
      error_message = "Firewall rule '${each.key}': source_* fields are only valid for INGRESS rules."
    }
    precondition {
      condition = !(
        length(each.value.source_service_accounts) > 0 &&
        length(each.value.target_tags) > 0
      )
      error_message = "Firewall rule '${each.key}': target_tags cannot be used with source_service_accounts. Use target_service_accounts instead."
    }
    precondition {
      condition = !(
        length(each.value.source_tags) > 0 &&
        length(each.value.source_service_accounts) > 0
      )
      error_message = "Firewall rule '${each.key}': choose one source selector: source_tags OR source_service_accounts."
    }
    precondition {
      condition = !(
        length(each.value.target_tags) > 0 &&
        length(each.value.target_service_accounts) > 0
      )
      error_message = "Firewall rule '${each.key}': choose one target selector: target_tags OR target_service_accounts."
    }
    precondition {
      condition = !(
        each.value.direction == "INGRESS" &&
        length(each.value.source_ranges) == 0 &&
        length(each.value.source_tags) == 0 &&
        length(each.value.source_service_accounts) == 0
      )
      error_message = "Firewall rule '${each.key}': INGRESS rules must set at least one of source_ranges, source_tags, or source_service_accounts."
    }
    precondition {
      condition = !(
        each.value.direction == "EGRESS" &&
        length(each.value.destination_ranges) == 0
      )
      error_message = "Firewall rule '${each.key}': EGRESS rules must set destination_ranges."
    }
    precondition {
      condition     = each.value.priority >= 0 && each.value.priority <= 65535
      error_message = "Firewall rule '${each.key}': priority must be between 0 and 65535."
    }

  }
}
