output "sa_cloud_build_runner" {
  value = google_service_account.cloud_build_runner.email
}

output "node_service_account" {
  value = data.google_compute_default_service_account.default.email
}