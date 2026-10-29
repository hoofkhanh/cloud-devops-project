resource "google_secret_manager_secret" "secrets" {
  for_each = toset(var.secret_ids)

  project   = var.project_id
  secret_id = each.value

  replication {
    auto {
    }
  }
}

resource "google_secret_manager_secret_version" "version_configuration" {
  for_each = google_secret_manager_secret.secrets

  secret      = each.value.id
  secret_data = file("${path.module}/secrets/${each.key}.txt")
}

data "google_secret_manager_secret_version" "secrets" {
  for_each = google_secret_manager_secret_version.version_configuration

  secret  = each.value.secret
  version = each.value.version
}