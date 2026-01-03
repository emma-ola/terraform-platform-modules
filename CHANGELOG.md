# Changelog

All notable changes to this repository will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [0.1.0] - 2026-01-02

### Added
- Initial set of production-grade Terraform platform modules.

#### Project module
- GCP project creation with optional folder support.
- Billing account attachment.
- API enablement for required services.
- Validation to enforce correct project, folder, and billing relationships.
- Designed for use as a foundational platform primitive.

#### Network module
- Custom VPC creation.
- Multi-region subnets with optional secondary IP ranges.
- Per-subnet VPC Flow Logs with secure defaults and validation.
- Data-driven firewall rules with strong guardrails.
- Cloud NAT with:
    - Multi-region support
    - Per-subnet primary and secondary range control
    - Logging configuration
    - Endpoint type support
- Static route management with safety validations.

### CI / Tooling
- Terraform formatting and validation via GitHub Actions.
- Static linting with `tflint`.
- Security scanning with `tfsec`.
- SARIF upload to GitHub Security for visibility.
- CI gating on HIGH and CRITICAL security findings.

---
