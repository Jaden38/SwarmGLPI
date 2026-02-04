variable "glpi_db_name" {
  description = "GLPI database name"
  type        = string
  default     = "glpi"
}

variable "glpi_db_user" {
  description = "GLPI database user"
  type        = string
  default     = "glpi"
}

variable "glpi_db_password" {
  description = "GLPI database password"
  type        = string
  sensitive   = true
}

variable "glpi_db_root_password" {
  description = "MariaDB root password"
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Domain name for GLPI (used for SSL)"
  type        = string
  default     = "glpi.local"
}

variable "timezone" {
  description = "Timezone for GLPI"
  type        = string
  default     = "Europe/Paris"
}
