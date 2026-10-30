output "project_id" {
  value = google_project.project.project_id
}

output "project_name" {
  value = google_project.project.name
}

output "org_id" {
  value = google_project.project.org_id
}

output "terraform_state" {
  value = google_storage_bucket.terraform_state.name
}