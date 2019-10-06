# ------------------------------------------------------------------------------
# REQUIRED VARIABLES
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "Project where resources will be created"
}

variable "serviceaccount_key" {
  description = "Service account key for the project"
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# ------------------------------------------------------------------------------

variable "keyring_name" {
  default = "keyring"
}

variable "keyring_location" {
  default = "global"
}

variable "storage_location" {
  default = "europe-west1"
}

variable "encryption_keys" {
  description = "Names of encryption keys to create (a storage bucket will also be created for each)"
  default = []
}

variable "apply_audit_config" {
  description = "Set this to false if you don't want to modify current project's IAM policy to apply audit config provided by scripts/add-audit-config"
  default     = true
}

variable "bucket_versioning_enabled" {
  description = "Set this to true to enable versioning for GS bucket that stores encrypted secrets"
  default     = false
}
