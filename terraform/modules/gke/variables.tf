variable "network" {
  type = object({
    network_name                      = string
    subnet_name                       = string
    secondary_range_name_gke_pods     = string
    secondary_range_name_gke_services = string
  })
}

variable "cluster_name" {
  type = string
}

variable "zone" {
  type = string
}

variable "project_id" {
  type = string
}