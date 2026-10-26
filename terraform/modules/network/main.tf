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


resource "google_compute_global_address" "private_ip_range" {
  project       = var.project_id
  name          = var.address_name
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = google_compute_network.vpc.name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  service = "servicenetworking.googleapis.com"
  network = google_compute_network.vpc.name
  reserved_peering_ranges = [
    google_compute_global_address.private_ip_range.name
  ]

  deletion_policy = "REMOVE_PEERING"
}