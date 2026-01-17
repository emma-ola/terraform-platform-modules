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

## Development

Common tasks are standardized using a Makefile.

```bash
make fmt        # format Terraform files
make fmt-check  # check formatting
make validate   # validate Terraform configuration
make ci         # run all CI checks locally
make help       # show all available commands
```

## Security scanning notes

This repository uses `tfsec` for Terraform security scanning.

The following rule is intentionally suppressed:

- **google-gke-enforce-pod-security-policy**

**Reason:**  
PodSecurityPolicy (PSP) is deprecated and removed in modern Kubernetes and GKE.  
Pod security is enforced using **Pod Security Admission (PSA)** and/or **Policy
Controller (Gatekeeper)** as a platform concern rather than legacy PSP.

All other security findings remain enabled and enforced.

