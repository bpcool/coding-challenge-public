variable "location" {
  type    = string
  default = "westeurope"
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "mysql_database_name" {
  type      = string
  sensitive = true
}

variable "mysql_flexible_server_fqdn" {
  type      = string
  sensitive = true
}