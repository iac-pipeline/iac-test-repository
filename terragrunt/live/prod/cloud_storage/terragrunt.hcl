terraform {
    source = "../../../modules/google_cloud_storage"
}

inputs = {
  bucket_name        = "test_bucket_0503-prod"
  location           = "europe-west2"
  force_destroy      = false
  versioning_enabled = true
  project            = "iac-pipeline-486415"
}

include {
    path = find_in_parent_folders("root.hcl")
}
