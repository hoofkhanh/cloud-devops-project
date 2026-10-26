resource "google_container_cluster" "my_cluster" {
  name               = var.cluster_name
  location           = var.zone
  network            = var.network.network_name
  subnetwork         = var.network.subnet_name
  initial_node_count = 1
  project            = var.project_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.network.secondary_range_name_gke_pods
    services_secondary_range_name = var.network.secondary_range_name_gke_services
  }

  deletion_protection = false

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "default_pool" {
  cluster  = google_container_cluster.my_cluster.name
  location = var.zone
  node_config {
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }
}