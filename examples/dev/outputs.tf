output "project_id" {
  value = module.project.project_id
}

output "enabled_apis" {
  value = module.project.enabled_apis
}

output "network_name" {
  value = module.network.network_name
}

output "network_id" {
  value = module.network.network_id
}

output "subnet_names" {
  value = module.network.subnet_names
}

output "subnet_self_links" {
  value = module.network.subnet_self_links
}

output "subnet_secondary_ranges" {
  value = module.network.subnet_secondary_ranges
}

output "firewall_rule_names" {
  value = module.network.firewall_rule_names
}

output "nat_router_names" {
  value = module.network.nat_router_names
}

output "nat_names" {
  value = module.network.nat_names
}
