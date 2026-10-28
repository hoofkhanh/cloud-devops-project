resource "google_project" "project" {
  name            = var.project_name
  project_id      = var.project_id
  billing_account = var.billing_account_id
  org_id          = var.org_id
  # deletion_policy = "DELETE"
}

locals {
  required_apis = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "cloudbuild.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.required_apis)

  project = google_project.project.id
  service = each.value

  disable_on_destroy = false
  depends_on = [
    google_project.project
  ]
}

