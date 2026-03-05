terraform {
    source = "../../../modules/cloud_store_2"
}

inputs = {
  bucket_name        = "test_bucket2"
  location           = "europe-west2"
  force_destroy      = false
  versioning_enabled = true
}

include {
    path = find_in_parent_folders("root.hcl")
}