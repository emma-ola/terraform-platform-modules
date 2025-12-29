variable "project_id" {
  description = "An existing GCP project ID to use for the dev example."
  type        = string
}

variable "project_name" {
  description = "Display name for the project."
  type        = string
  default     = "Dev Platform"
}

variable "billing_account" {
  description = "The Billing Account for the project"
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

variable "folder_parent" {
  description = "The Parent for the folder"
  type        = string
}

variable "folder_display_name" {
  description = "Display name for the folder"
  type        = string
  default     = "Dev"
}
