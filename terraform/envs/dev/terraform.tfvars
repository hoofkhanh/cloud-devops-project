project_id = "dev-devops-project-2026"
region     = "us-central1"


network = {
  network_name                      = "my-network"
  subnet_name                       = "my-subnet-1"
  subnet_cidr_range                 = "10.0.1.0/24"
  secondary_range_name_gke_pods     = "gke-pods"
  secondary_cidr_range_gke_pods     = "10.0.16.0/20"
  secondary_range_name_gke_services = "gke-services"
  secondary_cidr_range_gke_services = "10.0.3.0/24"
}
