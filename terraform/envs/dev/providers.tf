provider "google" {
  project = var.gcp.project_id
  region  = var.gcp.region
}


provider "helm" {
  kubernetes = {
    host = "https://${module.gke.endpoint}"

    token = data.google_client_config.default.access_token

    cluster_ca_certificate = base64decode(
      module.gke.ca_certificate
    )
  }
}

provider "kubernetes" {
  host = "https://${module.gke.endpoint}"

  token = data.google_client_config.default.access_token

  cluster_ca_certificate = base64decode(
    module.gke.ca_certificate
  )
}

data "google_client_config" "default" {}