variable "gcp" {
  type = object({
    project_id = string
    region     = string
    zone       = string
    location   = string
  })
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
    address_name                      = string
  })
}

variable "gke" {
  type = object({
    cluster_name    = string
    namespace       = string
    app_k8s_sa_name = string
  })
}

variable "service_accounts" {
  type = object({
    account_id_cloud_build_runner = string
  })
}

variable "artifact_registry" {
  type = object({
    repository_id = string
  })
}

variable "sql_databases" {
  type = object({
    instance_name    = string
    database_version = string
    sql_user_name    = string
  })
}

variable "root_password" {
  type      = string
  sensitive = true
}

variable "sql_user_password" {
  type      = string
  sensitive = true
}