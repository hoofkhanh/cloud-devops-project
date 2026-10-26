resource "google_storage_bucket" "build_source" {
  project                     = var.project_id
  name                        = "${var.project_id}-build-source"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy = true
}

resource "google_storage_bucket_iam_member" "storage_admin" {
  bucket = google_storage_bucket.build_source.name
  member = "serviceAccount:${var.sa_runner}"
  role   = "roles/storage.admin"
}