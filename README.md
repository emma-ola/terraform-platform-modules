# Terraform Platform Modules (GCP)

Opinionated, reusable Terraform modules to provision secure and consistent GCP infrastructure.
Designed to reduce duplication, prevent configuration drift, and enable safe upgrades via versioned releases.

## Modules
- **network**: VPC, subnets, and baseline firewall rules (secure defaults)
- **gke**: Private GKE cluster and node pools (platform-ready defaults)

## Philosophy
- Secure-by-default
- Minimal, well-validated inputs
- Versioned releases (teams pin module versions)
- CI guardrails (fmt/validate/lint/security checks)

## Usage
See `examples/dev` for a reference implementation.
