resource "google_compute_network" "vpc" {
  name                    = var.network.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = var.network.subnet_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.network.subnet_cidr_range


  secondary_ip_range {
    range_name    = var.network.secondary_range_name_gke_pods
    ip_cidr_range = var.network.secondary_cidr_range_gke_pods
  }

  secondary_ip_range {
    range_name    = var.network.secondary_range_name_gke_services
    ip_cidr_range = var.network.secondary_cidr_range_gke_services
  }
}