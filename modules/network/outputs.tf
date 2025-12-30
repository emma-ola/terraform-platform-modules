output "network_name" {
  description = "VPC name."
  value       = google_compute_network.this.name
}

output "network_id" {
  description = "VPC ID."
  value       = google_compute_network.this.id
}

output "subnet_names" {
  description = "Map of subnet keys to subnet names."
  value       = { for k, s in google_compute_subnetwork.this : k => s.name }
}

output "subnet_self_links" {
  description = "Map of subnet keys to subnet self_links."
  value       = { for k, s in google_compute_subnetwork.this : k => s.self_link }
}

# noinspection HILUnresolvedReference
output "subnet_secondary_ranges" {
  description = "Map of subnet keys to their secondary ranges (range_name -> cidr)."
  value = {
    for k, s in google_compute_subnetwork.this : k => {
      for r in s.secondary_ip_range : r.range_name => r.ip_cidr_range
    }
  }
}

output "firewall_rule_names" {
  description = "Names of firewall rules created by this module."
  value       = { for k, r in google_compute_firewall.rules : k => r.name }
}
