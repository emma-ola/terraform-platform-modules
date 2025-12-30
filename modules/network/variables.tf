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
  description = "Map of subnets to create. Each subnet supports optional secondary ranges."

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
  description = "Map of firewall rules to create. Supports ingress and egress rules"

  type = map(object({
    name                    = string
    description             = optional(string, null)
    direction               = optional(string, "INGRESS") # INGRESS or EGRESS
    priority                = optional(number, 1000)
    disabled                = optional(bool, false)
    source_ranges           = optional(list(string), [])
    source_tags             = optional(list(string), [])
    source_service_accounts = optional(list(string), [])
    destination_ranges      = optional(list(string), [])
    target_tags             = optional(list(string), [])
    target_service_accounts = optional(list(string), [])
    enable_logging          = optional(bool, false)

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

variable "nat" {
  description = "Optional Cloud NAT configuration."
  type = object({
    enabled = optional(bool, false)
    regions = optional(map(object({
      router_name = optional(string, null)
      nat_name    = optional(string, null)
      source_subnetwork_ip_ranges_to_nat = optional(string, "ALL_SUBNETWORKS_ALL_IP_RANGES")
      subnet_keys = optional(list(string), [])
    })), {})
  })

  default = {
    enabled = false
    regions = {}
  }

  validation {
    condition = contains([true, false], try(var.nat.enabled, false))
    error_message = "nat.enabled must be true or false."
  }
}
