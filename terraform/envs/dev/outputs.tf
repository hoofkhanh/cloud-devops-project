output "output_network" {
  value = module.network.vpc_network
}

output "output_gke_cluster_name" {
  value = module.gke.gke_cluster_name
}

output "output_sa_runner_email" {
  value = module.iam.sa_cloud_build_runner
}

output "output_storage_bucket_name" {
  value = module.storage.bucket_name
}

output "output_artifact_registry_repository_id" {
  value = module.artifact_registry.repository_id
}

output "output_sql_database_name" {
  value = module.sql_instance.sql_database_name
}

output "output_sql_user_name" {
  value = module.sql_instance.sql_user_name
}

