variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

variable "storage_account_name_for_upload" {
  type      = string
  sensitive = true
}

variable "containerapps_environment" {
  type = string
}

variable "frontend_app_name" {
  type = string
}

variable "backend_app_name" {
  type = string
}