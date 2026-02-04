output "frontend_network_id" {
  description = "Frontend network ID"
  value       = docker_network.frontend.id
}

output "backend_network_id" {
  description = "Backend network ID"
  value       = docker_network.backend.id
}

output "glpi_data_volume" {
  description = "GLPI data volume name"
  value       = docker_volume.glpi_data.name
}

output "db_data_volume" {
  description = "Database data volume name"
  value       = docker_volume.db_data.name
}

output "certs_volume" {
  description = "Certificates volume name"
  value       = docker_volume.certs.name
}

output "db_password_secret_id" {
  description = "Database password secret ID"
  value       = docker_secret.db_password.id
}

output "db_root_password_secret_id" {
  description = "Database root password secret ID"
  value       = docker_secret.db_root_password.id
}
