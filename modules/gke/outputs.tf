output "name" {
  description = "GKE cluster name."
  value       = google_container_cluster.this.name
}

output "id" {
  description = "GKE cluster resource ID."
  value       = google_container_cluster.this.id
}

output "endpoint" {
  description = "Kubernetes API endpoint (may be private depending on config)."
  value       = google_container_cluster.this.endpoint
}

output "ca_certificate" {
  description = "Base64 encoded public CA certificate for the cluster."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "node_pool_names" {
  description = "Map of node pool keys to created node pool names."
  value       = { for k, np in google_container_node_pool.this : k => np.name }
}

output "node_service_account_email" {
  description = "Email of the node service account created by the module (if enabled)."
  value       = var.create_node_service_account ? google_service_account.nodes[0].email : null
}
