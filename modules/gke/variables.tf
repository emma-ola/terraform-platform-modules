variable "project_id" {
  description = "GCP project ID where the cluster will be created."
  type        = string
}

variable "name" {
  description = "GKE cluster name."
  type        = string
}

variable "location" {
  description = "Cluster location, region for regional clusters, or zone for zonal clusters."
  type        = string
}

variable "regional" {
  description = "If true, create a regional cluster. If false, create a zonal cluster."
  type        = bool
  default     = true
}

variable "network_self_link" {
  description = "Self link of the VPC network."
  type        = string
}

variable "subnetwork_self_link" {
  description = "Self link of the subnetwork where nodes will live."
  type        = string
}

variable "ip_range_pods" {
  description = "Secondary range name for GKE Pods."
  type        = string
}

variable "ip_range_services" {
  description = "Secondary range name for GKE Services."
  type        = string
}

variable "release_channel" {
  description = "GKE release channel."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, or STABLE."
  }
}

variable "deletion_protection" {
  description = "Whether deletion protection is enabled on the cluster."
  type        = bool
  default     = false
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity for the cluster."
  type        = bool
  default     = true
}

variable "private_cluster" {
  description = "Whether to create a private cluster."
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "If true, the Kubernetes API endpoint is private-only. If false, public endpoint is enabled."
  type        = bool
  default     = true
}

variable "master_ipv4_cidr_block" {
  description = "The /28 CIDR block for the GKE master private control plane when private_cluster=true."
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks allowed to reach the Kubernetes control plane endpoint.Required when enable_private_endpoint=true."
  type = list(object({
    cidr_block   = string
    display_name = optional(string)
  }))
  default = []
}

variable "node_pools" {
  description = "Map of node pools to create. This module removes the default node pool and creates node pools explicitly."
  type = map(object({
    machine_type        = string
    min_count           = number
    max_count           = number
    autoscaling_enabled = optional(bool, true)
    node_count          = optional(number, null)
    disk_size_gb        = optional(number, 20)
    disk_type           = optional(string, "pd-balanced")
    spot                = optional(bool, false)
    service_account     = optional(string, null)
    labels              = optional(map(string), {})
    tags                = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string # NO_SCHEDULE, PREFER_NO_SCHEDULE, NO_EXECUTE
    })), [])
    oauth_scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
    upgrade_settings = optional(object({
      max_surge       = optional(number, 1)
      max_unavailable = optional(number, 0)
    }), {})
  }))

  default = {
    default = {
      machine_type = "e2-standard-4"
      min_count    = 1
      max_count    = 3
    }
  }
}

variable "maintenance" {
  description = <<EOT
Maintenance policy configuration.
- recurring_window: RFC3339 timestamps for start/end and an RFC5545 recurrence rule
- exclusions: blackout windows keyed by name
EOT

  type = object({
    recurring_window = optional(object({
      start_time = string # RFC3339
      end_time   = string # RFC3339
      recurrence = string # RFC5545 RRULE, e.g. "FREQ=WEEKLY;BYDAY=SA,SU"
    }), null)

    exclusions = optional(map(object({
      start_time = string # RFC3339
      end_time   = string # RFC3339
      scope      = optional(string, "NO_UPGRADES") # NO_UPGRADES, NO_MINOR_UPGRADES, or NO_MINOR_OR_NODE_UPGRADES
    })), {})
  })

  default = {
    recurring_window = null
    exclusions       = {}
  }
}

variable "labels" {
  description = "Labels applied to the GKE cluster resource."
  type        = map(string)
  default     = {}
}
