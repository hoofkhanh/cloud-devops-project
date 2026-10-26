
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region where the subnet will be created"
  type        = string
}

variable "network" {
  type = object({
    network_name                      = string
    subnet_name                       = string
    subnet_cidr_range                 = string
    secondary_range_name_gke_pods     = string
    secondary_cidr_range_gke_pods     = string
    secondary_range_name_gke_services = string
    secondary_cidr_range_gke_services = string
  })
}


variable "address_name" {
  type = string
}