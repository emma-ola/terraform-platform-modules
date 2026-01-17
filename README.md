# Terraform Platform Modules (GCP)

Opinionated, reusable Terraform modules to provision **secure and consistent**
Google Cloud infrastructure.

Designed to reduce duplication, prevent configuration drift, and enable safe
upgrades via versioned releases.

---

## Modules

- **network**
    - VPC creation
    - Multi-region subnets with optional secondary ranges
    - Firewall rules with validation and guardrails
    - Cloud NAT with scoped subnet and IP-range support
    - Routes and VPC Flow Logs

- **gke**
    - Private GKE clusters
    - Data-driven node pools
    - Secure node defaults (COS, Shielded VMs, metadata hardening)
    - Workload Identity enabled by default

---

## Philosophy

- Secure-by-default
- Minimal, well-validated inputs
- Clear separation of concerns (project → network → GKE)
- Versioned releases (teams pin module versions)
- CI guardrails (formatting, validation, linting, security scanning)

---

## Security & Guardrails

This repository is designed as a **production-grade Terraform platform**, not a
collection of ad-hoc modules. Security is enforced primarily through opinionated
defaults and module-level guarantees rather than relying on callers.

### Built-in security controls

- **GKE hardening**
    - Private clusters by default
    - Legacy metadata endpoints disabled on all nodes
    - Workload Metadata configured (`GKE_METADATA`)
    - Shielded nodes enabled (Secure Boot + Integrity Monitoring)
    - Container-Optimized OS (`COS_CONTAINERD`) enforced for node images
    - Network Policy support enabled at the cluster level

- **Network security**
    - VPC Flow Logs supported and configurable per subnet
    - Firewall rules validated to prevent conflicting or unsafe configurations
    - Cloud NAT configurable with scoped subnet and IP-range selection

- **Platform standards**
    - Baseline resource labels enforced at the module level
    - Caller-supplied labels merged with platform defaults
    - Guardrails implemented using Terraform preconditions

### Automated security scanning

- **Static analysis:** `tflint`
- **Security scanning:** `tfsec` with SARIF upload to GitHub Security
- Security findings are:
    - Addressed through secure defaults where applicable, or
    - Explicitly suppressed with documented justification

#### Suppressed tfsec rule

- **google-gke-enforce-pod-security-policy**

**Reason:**  
PodSecurityPolicy (PSP) is deprecated and removed in modern Kubernetes and GKE.
Pod security is enforced via **Pod Security Admission (PSA)** and/or **Policy
Controller (Gatekeeper)** as a platform concern rather than legacy PSP.

All other security findings remain enabled and enforced.

---

## Usage

See `examples/dev` and `examples/gke-dev` for a reference implementation demonstrating composition of
the project, network, and GKE modules.

---

## Development

Common tasks are standardized using a Makefile.

```bash
make fmt        # format Terraform files
make fmt-check  # check formatting
make validate   # validate Terraform configuration
make ci         # run all CI checks locally
make help       # show all available commands
