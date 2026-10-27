output "gke_cluster_name" {
  value = google_container_cluster.my_cluster.name
}

output "endpoint" {
  value = google_container_cluster.my_cluster.endpoint
}

output "ca_certificate" {
  value     = google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate
  sensitive = true
}