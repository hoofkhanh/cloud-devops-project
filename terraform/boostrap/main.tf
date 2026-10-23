resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  billing_account = var.billing_account_id
  org_id          = var.org_id
  # deletion_policy = "DELETE"
}

resource "google_project_service" "network_api" {
  project = google_project.project.id
  service = "compute.googleapis.com"

  disable_on_destroy = false
  depends_on = [
    google_project.project
  ]
}