
variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "virtual_network_name" {
  type = string
}

variable "virtual_network_id" {
  type = string
}

variable "managed_identity_id" {
  type = string
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password_from_keyvault" {
  type      = string
  sensitive = true
}

variable "log_analytics_workspace_id" {
  type = string
}
