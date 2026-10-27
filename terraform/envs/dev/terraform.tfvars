gcp = {
  project_id = "dev-devops-project-2026"
  region     = "us-central1"
  zone       = "us-central1-a"
  location   = "us-central1"
}

network = {
  network_name                      = "my-network"
  subnet_name                       = "my-subnet-1"
  subnet_cidr_range                 = "10.0.1.0/24"
  secondary_range_name_gke_pods     = "gke-pods"
  secondary_cidr_range_gke_pods     = "10.0.16.0/20"
  secondary_range_name_gke_services = "gke-services"
  secondary_cidr_range_gke_services = "10.0.3.0/24"
  address_name                      = "google-managed-services-my-network"
}

gke = {
  cluster_name    = "my-cluster"
  namespace       = "my-ns"
  app_k8s_sa_name = "app-ksa"
}

service_accounts = {
  account_id_cloud_build_runner = "cloud-build-runner"
}


artifact_registry = {
  repository_id = "my-repo"
}

sql_databases = {
  instance_name    = "my-sql-instance"
  database_version = "MYSQL_8_0"
  sql_user_name    = "khanh"
}

wif_github = {
  workload_identity_pool_id          = "github-pool"
  workload_identity_pool_provider_id = "github-provider"
  github_repository                  = "hoofkhanh/cloud-devops-project"
}

argocd = {
  argocd_chart_version = "10.10.5"
}

monitoring_chart_version = "92.13.0"