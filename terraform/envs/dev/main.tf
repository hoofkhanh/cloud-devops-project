module "network" {
  source = "../../modules/network"

  project_id = var.project_id
  region     = var.region
  network    = var.network
}