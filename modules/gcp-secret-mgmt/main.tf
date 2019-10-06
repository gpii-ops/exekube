# ------------------------------------------------------------------------------
# TERRAFORM / PROVIDER CONFIG
# ------------------------------------------------------------------------------

terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "gcs" {}
}

provider "google" {
  project     = "${var.project_id}"
  credentials = "${var.serviceaccount_key}"

  # Setting an alias allows 'terraform import' to handle variables correctly. /shrug
  # https://github.com/hashicorp/terraform/issues/13018#issuecomment-291547654
  alias = "google"
}

# ------------------------------------------------------------------------------
# Support for AuditConfigs is missing in terraform-provider-google
# GitHub issue:
# https://github.com/terraform-providers/terraform-provider-google/issues/936
# We use the add-audit-config script for now
# ------------------------------------------------------------------------------

resource "null_resource" "add_audit_config" {
  count = "${var.apply_audit_config ? 1 : 0}"

  provisioner "local-exec" {
    command    = "bash ${path.module}/scripts/add-audit-config"
    on_failure = "continue"
  }
}

# ------------------------------------------------------------------------------
# PROJECT KEY RING
# ------------------------------------------------------------------------------

resource "google_kms_key_ring" "key_ring" {
  name     = "${var.keyring_name}"
  location = "${var.keyring_location}"

  provisioner "local-exec" {
    command = "sleep 10"
  }

  # KMS Keyrings are indestructible. When Terraform "destroys" them, it
  # disables and marks for deletion each Key in the Keyring. This forces us to
  # handle Keyrings specially (e.g. not destroying this module as part of the
  # regular `rake destroy` workflow, the workflow for migrating between
  # regions).
  #
  # Therefore, destroying this module is usually a mistake that is going to
  # cause trouble, and we prevent it.
  lifecycle {
    prevent_destroy = true
  }

  # We must specify the provider due to the workaround for
  # https://github.com/hashicorp/terraform/issues/13018#issuecomment-291547654
  provider = "google.google"
}

# ------------------------------------------------------------------------------
# CRYPTO KEYS AND STORAGE BUCKETS
# ------------------------------------------------------------------------------

resource "google_kms_crypto_key" "encryption_keys" {
  count = "${length(var.encryption_keys)}"

  name     = "${element(var.encryption_keys, count.index)}"
  key_ring = "${google_kms_key_ring.key_ring.id}"

  # See note in key_ring.
  lifecycle {
    prevent_destroy = true
  }

  # We must specify the provider due to the workaround for
  # https://github.com/hashicorp/terraform/issues/13018#issuecomment-291547654
  provider = "google.google"
}

resource "google_storage_bucket" "gcs_buckets" {
  count = "${length(var.encryption_keys)}"

  name          = "${var.project_id}-${element(var.encryption_keys, count.index)}-secrets"
  storage_class = "REGIONAL"
  location      = "${var.storage_location}"
  force_destroy = true

  versioning = {
    enabled = "${var.bucket_versioning_enabled}"
  }

  # We must specify the provider due to the workaround for
  # https://github.com/hashicorp/terraform/issues/13018#issuecomment-291547654
  provider = "google.google"
}

# ------------------------------------------------------------------------------
# TEMPLATE FOR GIVING GRANULAR ACCESS
# ------------------------------------------------------------------------------


/*
# Full control over the kerring and all encryption keys in it
resource "google_kms_key_ring_iam_binding" "keyring_admins" {
  key_ring_id = ""
  role        = "roles/cloudkms.admin"

  members = []
}

# Access to all encryption keys
resource "google_kms_key_ring_iam_binding" "keyring_users" {
  key_ring_id = ""
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = []
}

resource "google_kms_crypto_key_iam_binding" "cryptokey_users" {
  crypto_key_id = ""
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = []
}


# Allow fetching and pushing secrets in the bucket
resource "google_storage_bucket_iam_binding" "bucket_admins" {
  bucket = ""

  role = "roles/storage.objectAdmin"

  members = []
}
*/

