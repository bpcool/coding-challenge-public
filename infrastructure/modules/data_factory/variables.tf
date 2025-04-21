# ------------------------
# Variables
# ------------------------
variable "location" {
  type    = string
}

variable "resource_group_name" {
  type    = string
}

variable "storage_account_name_for_upload" {
  type      = string
  sensitive = true
}

variable "virtual_network_name" {
  type    = string
}

variable "mysql_flexible_server_id" {
  type    = string
}
variable "mysql_fqdn" {
  type    = string
}

variable "mysql_admin_username" {
   type    = string
}

variable "mysql_admin_password" {
   type    = string
}

variable "mysql_database_name" {
   type    = string
}
