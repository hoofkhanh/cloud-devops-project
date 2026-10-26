output "sql_database_name" {
  value = google_sql_database_instance.my_sql_instance.name
}

output "sql_user_name" {
  value = google_sql_user.sql_user.name
}