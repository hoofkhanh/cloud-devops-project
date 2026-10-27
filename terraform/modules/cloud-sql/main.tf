resource "google_sql_database_instance" "my_sql_instance" {
  name             = var.instance_name
  database_version = var.database_version
  region           = var.region
  project          = var.project_id

  settings {
    tier = "db-custom-2-7680"
    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_self_link
    }
  }

  root_password       = var.root_password
  deletion_protection = false

}

resource "google_sql_user" "sql_user" {
  name     = var.sql_user_name
  instance = google_sql_database_instance.my_sql_instance.name
  password = var.sql_user_password
  project  = var.project_id
}