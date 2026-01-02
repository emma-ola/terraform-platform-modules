# Network Module

Production-grade Terraform module for building **foundational networking** in Google Cloud Platform (GCP).

This module is designed for **platform and infrastructure teams** who need reusable, opinionated, and safe networking primitives that can be shared across environments and teams.

---

## What this module provides

This module can optionally manage:

- Custom-mode **VPC network**
- **One or more subnets** across regions
- Optional **secondary IP ranges** per subnet
- **Firewall rules** (data-driven, with strong guardrails)
- **Cloud NAT** (multi-region, per-subnet, primary/secondary range control)
- **Static routes** (explicit, validated, tag-scoped)

All features are **opt-in** and controlled via input variables.

---

## Design principles

- **Foundational, not opinionated about workloads**  
  This module supports GKE, VMs, serverless, hybrid networking, and more — without hardcoding for any single product.

- **Safe defaults, explicit intent**  
  Powerful features (NAT, routes, firewall rules) are opt-in and validated to prevent common misconfigurations.

- **Composable & reusable**  
  Outputs are designed to be consumed by other platform modules (e.g. GKE, service projects).

- **Fail fast**  
  Extensive validation and preconditions catch invalid configurations during `terraform plan`.

---

## Usage

### Minimal example (VPC + one subnet)

```hcl
module "network" {
  source      = "../../modules/network"
  project_id  = var.project_id
  network_name = "platform-vpc"

  subnets = {
    apps_us_central1 = {
      name          = "apps-us-central1"
      region        = "us-central1"
      ip_cidr_range = "10.10.0.0/20"
    }
  }
}
```

### Subnets with secondary ranges

Secondary ranges are optional and defined per subnet.

```hcl
subnets = {
  apps_us_central1 = {
    name          = "apps-us-central1"
    region        = "us-central1"
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
}
```

### Firewall rules

Firewall rules are defined as a map of rule objects and validated to prevent invalid combinations.

**Example: internal access + service-account based access**

```hcl
manage_firewall_rules = true

firewall_rules = {
  allow_internal = {
    name        = "allow-internal"
    direction   = "INGRESS"
    priority    = 1000
    source_ranges = ["10.0.0.0/8"]

    allows = [
      { protocol = "tcp" },
      { protocol = "udp" },
      { protocol = "icmp" }
    ]
  }

  allow_ops_to_admin = {
    name        = "allow-ops-to-admin"
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
  }
}
```

The module enforces:

- `INGRESS` rules must define a source
- `EGRESS` rules must define a destination
- allow/deny exclusivity
- valid combinations of tags and service accounts

### Cloud NAT

Cloud NAT is optional and configured per region.

**NAT primary ranges only (common)**

```hcl
nat = {
  enabled = true
  regions = {
    europe-west2 = {
      source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

      subnets = {
        backend_europe_west2 = {
          nat_primary = true
        }
      }
    }
  }
}
```

**NAT secondary ranges only (e.g. pods)**

```hcl
nat = {
  enabled = true
  regions = {
    europe-west2 = {
      source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

      subnets = {
        apps_europe_west2 = {
          nat_primary           = false
          secondary_range_names = ["pods"]
        }
      }
    }
  }
}
```

**NAT with logging and endpoint types**

```hcl
nat = {
  enabled = true
  regions = {
    europe-west2 = {
      endpoint_types = ["ENDPOINT_TYPE_VM"]

      logging = {
        enabled = true
        filter  = "ALL"
      }

      source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
    }
  }
}
```

### Routes

Routes are optional and must explicitly define exactly one next hop.

**Example: tag-scoped default internet route**

```hcl
manage_routes = true

routes = {
  tagged_default_internet = {
    name        = "tagged-default-internet"
    dest_range  = "0.0.0.0/0"
    priority    = 1000
    tags        = ["egress-internet"]

    next_hop_gateway = "default-internet-gateway"
  }
}
```

This prevents unintended global routing changes.

---

## Outputs

Common outputs include:

- `network_name`
- `network_id`
- `subnet_names`
- `subnet_self_links`
- `subnet_secondary_ranges`
- `firewall_rule_names`
- `nat_router_names`
- `nat_names`
- `route_names`

These outputs are intended to be consumed by other platform modules.

---

## Notes

- This module does not create VPNs, Interconnects, or load balancers.
- Routes and NAT next hops must reference externally-created resources.
- This module is designed to be a foundation layer, not an application stack.

---

## License

MIT

