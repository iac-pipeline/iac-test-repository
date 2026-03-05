terraform {
  backend "gcs" {}
}

resource "google_storage_bucket" "bucket" {
    name          = var.bucket_name
    location      = var.location
    force_destroy = var.force_destroy
    project = var.project

    versioning {
        enabled = var.versioning_enabled
    }
}