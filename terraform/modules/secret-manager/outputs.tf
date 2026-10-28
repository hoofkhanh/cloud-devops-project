output "sql_secrets" {
  value = {
    for key, secret in data.google_secret_manager_secret_version.sql_secrets :
    key => {
      for line in split("\n", trimspace(secret.secret_data)):
      split("=", line)[0] => split("=", line)[1]
    }
  }

  sensitive = true
}

output "secrets" {
  value = {
    for key, secret in data.google_secret_manager_secret_version.sql_secrets :
    key => secret.secret
  }
}

output "sql_secret_id" {
  value = google_secret_manager_secret.secrets["sql"].secret_id
}