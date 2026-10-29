resource "google_service_account" "cloud_build_runner" {
  project    = var.project_id
  account_id = "cloud-build-runner"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.cloud_build_runner.email}"
  role    = "roles/logging.logWriter"
}

resource "google_service_account" "cloud_sql_sa" {
  project    = var.project_id
  account_id = "cloudsql-client"
}

resource "google_project_iam_member" "cloud_sql_sa_cloud_sql_client" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.cloud_sql_sa.email}"
  role    = "roles/cloudsql.client"
  condition {
    expression  = "resource.name=='projects/${var.project_id}/instances/${var.sql_instance_name}' && resource.service == 'sqladmin.googleapis.com'"
    title       = "OnlyMySQLInstance"
    description = "Allow connection only to my-sql-instance"
  }
}

resource "google_secret_manager_secret_iam_member" "cloud_sql_sa_secret_accessor" {
  project   = var.project_id
  member    = "serviceAccount:${google_service_account.cloud_sql_sa.email}"
  role      = "roles/secretmanager.secretAccessor"
  secret_id = var.sql_secret_id
}

resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.cloud_sql_sa.id
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.app_k8s_sa_name}]"
  role               = "roles/iam.workloadIdentityUser"
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}

resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = var.workload_identity_pool_id
  display_name              = "GitHub Actions Pool"
}


resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_provider_id = var.workload_identity_pool_provider_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  display_name                       = "GitHub Actions Provider"
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  attribute_condition = "assertion.repository == '${var.github_repository}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account_iam_member" "github_cloud_build_runner" {
  service_account_id = google_service_account.cloud_build_runner.id
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.current.number}/locations/global/workloadIdentityPools/${var.workload_identity_pool_id}/attribute.repository/${var.github_repository}"
  role               = "roles/iam.workloadIdentityUser"
}