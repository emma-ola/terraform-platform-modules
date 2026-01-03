# GKE Module

Production-grade Terraform module for creating a reusable GKE cluster as a platform primitive.

This module is designed to be composed with the repo’s foundational modules:
- `project` module (project bootstrapping)
- `network` module (VPC, subnets, secondary ranges, NAT, firewall, routes)

---

## Key defaults

- Private cluster by default
- Workload Identity enabled by default
- Default node pool removed; node pools are created explicitly via `node_pools`

---

## Example

```hcl
module "gke" {
  source    = "../../modules/gke"
  project_id = var.project_id
  name       = "platform-dev"
  location   = "us-central1"
  regional   = true

  network_self_link    = module.network.network_id
  subnetwork_self_link = module.network.subnet_self_links["gke_us_central1"]

  ip_range_pods     = "pods"
  ip_range_services = "svc"

  node_pools = {
    default = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
    }
  }
}
