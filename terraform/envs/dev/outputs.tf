output "network" {
  value = {
    network_name                      = module.network.vpc_network.network_name
    subnet_name                       = module.network.vpc_network.subnet_name
    secondary_range_name_gke_pods     = module.network.vpc_network.secondary_range_name_gke_pods
    secondary_range_name_gke_services = module.network.vpc_network.secondary_range_name_gke_services
  }
}