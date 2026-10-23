output "vpc_network" {
  value = {
    network_name                      = google_compute_network.vpc.name
    subnet_name                       = google_compute_subnetwork.subnet.name
    secondary_range_name_gke_pods     = google_compute_subnetwork.subnet.secondary_ip_range[0].range_name
    secondary_range_name_gke_services = google_compute_subnetwork.subnet.secondary_ip_range[1].range_name
  }
}