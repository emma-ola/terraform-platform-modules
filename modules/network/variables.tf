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
