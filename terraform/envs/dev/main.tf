module "network" {
  source = "../../modules/network"

  project_id   = var.gcp.project_id
  region       = var.gcp.region
  network      = var.network
  address_name = var.network.address_name
}

module "gke" {
  source = "../../modules/gke"

  cluster_name = var.gke.cluster_name
  network      = module.network.vpc_network
  zone         = var.gcp.zone
  project_id   = var.gcp.project_id
}

module "iam" {
  source = "../../modules/iam"

  project_id                         = var.gcp.project_id
  account_id_cloud_build_runner      = var.service_accounts.account_id_cloud_build_runner
  sql_instance_name                  = module.sql_instance.sql_database_name
  namespace                          = var.gke.namespace
  app_k8s_sa_name                    = var.gke.app_k8s_sa_name
  workload_identity_pool_id          = var.wif_github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.wif_github.workload_identity_pool_provider_id
  github_repository                  = var.wif_github.github_repository
  sql_secret_id                      = module.secret_manager.sql_secret_id
}

module "storage" {
  source = "../../modules/cloud-storage"

  project_id = var.gcp.project_id
  location   = var.gcp.location
  sa_runner  = module.iam.sa_cloud_build_runner
}

module "artifact_registry" {
  source = "../../modules/artifact-registry"

  project_id           = var.gcp.project_id
  region               = var.gcp.region
  location             = var.gcp.location
  repository_id        = var.artifact_registry.repository_id
  sa_runner            = module.iam.sa_cloud_build_runner
  node_service_account = module.iam.node_service_account
}

module "sql_instance" {
  source = "../../modules/cloud-sql"

  instance_name     = var.sql_databases.instance_name
  database_version  = var.sql_databases.database_version
  region            = var.gcp.region
  project_id        = var.gcp.project_id
  root_password     = module.secret_manager.secrets_data["sql"]["MYSQL_ROOT_PASSWORD"]
  sql_user_name     = module.secret_manager.secrets_data["sql"]["MYSQL_USER"]
  sql_user_password = module.secret_manager.secrets_data["sql"]["MYSQL_PASSWORD"]
  network_self_link = module.network.vpc_network.self_link

  depends_on = [module.network]
}

module "argocd" {
  source = "../../modules/argocd"

  argocd_chart_version = var.argocd.argocd_chart_version

  depends_on = [module.gke]
}

module "monitoring" {
  source = "../../modules/monitoring"

  grafana_csrf_trusted_origins = var.grafana_csrf_trusted_origins
  monitoring_chart_version     = var.monitoring_chart_version
  grafana_port                 = var.grafana_port
  smtp_username                = module.secret_manager.secrets_data["grafana"]["smtp-username"]
  smtp_password                = module.secret_manager.secrets_data["grafana"]["smtp-password"]

  depends_on = [module.gke]
}

module "secret_manager" {
  source = "../../modules/secret-manager"

  project_id = var.gcp.project_id
  secret_ids = var.secret_ids
}