variable "project_id" {
  description = "GCP project ID where the network will be created."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode: REGIONAL or GLOBAL."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  description = <<EOT
Map of subnets to create. Key is an identifier (e.g., 'apps-us-central1').
Each subnet supports optional secondary ranges for use cases like GKE.
EOT

  type = map(object({
    name                     = string
    region                   = string
    ip_cidr_range            = string
    private_ip_google_access = optional(bool, true)

    secondary_ranges = optional(map(object({
      range_name    = string
      ip_cidr_range = string
    })), {})
  }))
}

variable "manage_firewall_rules" {
  description = "If true, create firewall rules defined in firewall_rules."
  type        = bool
  default     = false
}

variable "firewall_rules" {
  description = <<EOT
Map of firewall rules to create. Key is a stable identifier.
Use either source_ranges or source_tags (or neither).
Use either target_tags or target_service_accounts (or neither).
EOT

  type = map(object({
    name        = string
    description = optional(string, null)
    direction   = optional(string, "INGRESS") # INGRESS or EGRESS
    priority    = optional(number, 1000)
    disabled    = optional(bool, false)
    source_ranges = optional(list(string), [])
    source_tags   = optional(list(string), [])
    source_service_accounts = optional(list(string), [])
    destination_ranges = optional(list(string), [])
    target_tags            = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
    enable_logging = optional(bool, false)

    allows = optional(list(object({
      protocol = string
      ports    = optional(list(string), null)
    })), [])
    denies = optional(list(object({
      protocol = string
      ports    = optional(list(string), null)
    })), [])
  }))

  default = {}
}
