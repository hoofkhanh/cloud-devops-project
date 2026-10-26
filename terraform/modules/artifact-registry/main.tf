resource "google_artifact_registry_repository" "my_repo" {
  project       = var.project_id
  location      = var.location
  repository_id = var.repository_id
  format        = "DOCKER"
}

resource "google_artifact_registry_repository_iam_member" "writer" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.my_repo.id
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${var.sa_runner}"
}

resource "google_artifact_registry_repository_iam_member" "reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.my_repo.id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${var.node_service_account}"
}