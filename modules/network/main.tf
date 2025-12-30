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

locals {
  nat_enabled = try(var.nat.enabled, false)
  subnet_keys_by_region = {
    for r in distinct([for _, s in var.subnets : s.region]) :
    r => [for k, s in var.subnets : k if s.region == r]
  }
  nat_regions = local.nat_enabled ? try(var.nat.regions, {}) : {}
}

resource "google_compute_router" "this" {
  for_each = local.nat_regions

  name    = coalesce(each.value.router_name, "${var.network_name}-cr-${each.key}")
  project = var.project_id
  region  = each.key
  network = google_compute_network.this.id

  lifecycle {
    precondition {
      condition     = contains(keys(local.subnet_keys_by_region), each.key)
      error_message = "NAT configured for region '${each.key}' but no subnets exist in that region."
    }
  }
}

resource "google_compute_router_nat" "this" {
  for_each = local.nat_regions

  name                               = coalesce(each.value.nat_name, "${var.network_name}-nat-${each.key}")
  project                            = var.project_id
  region                             = each.key
  router                             = google_compute_router.this[each.key].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = each.value.source_subnetwork_ip_ranges_to_nat

  dynamic "subnetwork" {
    for_each = each.value.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS"
      ? toset(each.value.subnet_keys)
      : toset([])

    content {
      name                    = google_compute_subnetwork.this[subnetwork.value].self_link
      source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
    }
  }

  lifecycle {
    precondition {
      condition = contains(["ALL_SUBNETWORKS_ALL_IP_RANGES", "LIST_OF_SUBNETWORKS"], each.value.source_subnetwork_ip_ranges_to_nat)
      error_message = "NAT region '${each.key}': source_subnetwork_ip_ranges_to_nat must be ALL_SUBNETWORKS_ALL_IP_RANGES or LIST_OF_SUBNETWORKS."
    }

    precondition {
      condition = !(
      each.value.source_subnetwork_ip_ranges_to_nat == "LIST_OF_SUBNETWORKS" &&
      length(each.value.subnet_keys) == 0
      )
      error_message = "NAT region '${each.key}': when using LIST_OF_SUBNETWORKS, subnet_keys must be non-empty."
    }

    precondition {
      condition = alltrue([
        for sk in each.value.subnet_keys :
        contains(keys(var.subnets), sk)
      ])
      error_message = "NAT region '${each.key}': one or more subnet_keys do not exist in var.subnets."
    }

    precondition {
      condition = alltrue([
        for sk in each.value.subnet_keys :
        var.subnets[sk].region == each.key
        ])
      error_message = "NAT region '${each.key}': subnet_keys must reference subnets in the same region."
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
