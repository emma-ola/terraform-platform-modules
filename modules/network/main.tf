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
