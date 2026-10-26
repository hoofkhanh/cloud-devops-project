resource "google_service_account" "cloud_build_runner" {
  project    = var.project_id
  account_id = "cloud-build-runner"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.cloud_build_runner.email}"
  role    = "roles/logging.logWriter"
}

resource "google_service_account" "cloud_sql_client" {
  project    = var.project_id
  account_id = "cloudsql-client"
}

resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  member  = "serviceAccount:${google_service_account.cloud_sql_client.email}"
  role    = "roles/cloudsql.client"
  condition {
    expression  = "resource.name=='projects/${var.project_id}/instances/${var.sql_instance_name}' && resource.service == 'sqladmin.googleapis.com'"
    title       = "OnlyMySQLInstance"
    description = "Allow connection only to my-sql-instance"
  }
}

resource "google_service_account_iam_member" "workload_identity_user" {
  service_account_id = google_service_account.cloud_sql_client.id
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.app_k8s_sa_name}]"
  role               = "roles/iam.workloadIdentityUser"
}

data "google_compute_default_service_account" "default" {
  project = var.project_id
}