variable "project_id" {
  description = "An existing GCP project ID to use for the dev example."
  type        = string
}

variable "region" {
  description = "Default region for resources."
  type        = string
  default     = "us-central1"
}

variable "labels" {
  description = "Standard labels used by the platform modules."
  type        = map(string)
  default = {
    env         = "dev"
    owner       = "tomide"
    cost_center = "platform"
  }
}
