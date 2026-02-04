terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Frontend network (nginx to external)
resource "docker_network" "frontend" {
  name   = "glpi_frontend"
  driver = "overlay"
  attachable = true
}

# Backend network (nginx <-> glpi <-> mariadb)
resource "docker_network" "backend" {
  name   = "glpi_backend"
  driver = "overlay"
  attachable = true
}

# Persistent volumes
resource "docker_volume" "glpi_data" {
  name = "glpi_data"
}

resource "docker_volume" "db_data" {
  name = "glpi_db_data"
}

resource "docker_volume" "certs" {
  name = "glpi_certs"
}

resource "docker_volume" "nginx_conf" {
  name = "glpi_nginx_conf"
}

# Docker secrets for sensitive data
resource "docker_secret" "db_password" {
  name = "glpi_db_password"
  data = base64encode(var.glpi_db_password)
}

resource "docker_secret" "db_root_password" {
  name = "glpi_db_root_password"
  data = base64encode(var.glpi_db_root_password)
}
