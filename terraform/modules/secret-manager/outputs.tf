output "secrets_data" {
  value = {
    for key, secret in data.google_secret_manager_secret_version.secrets :
    key => {
      for line in split("\n", trimspace(secret.secret_data)) :
      split("=", line)[0] => split("=", line)[1]
    }
  }

  sensitive = true
}

output "secrets" {
  value = {
    for key, secret in data.google_secret_manager_secret_version.secrets :
    key => secret.secret
  }
}

output "sql_secret_id" {
  value = google_secret_manager_secret.secrets["sql"].secret_id
}

# output "grafana_secret_id" {
#   value = google_secret_manager_secret.secrets["grafana"].secret_id
# }
