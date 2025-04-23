variable "location" {
  type    = string
  default = "centralus"
}

variable "resource_group_name" {
  type    = string
  default = "rg-teqwerk-dev-centralus-01"
}

variable "mysql_admin_username" {
  type    = string
  default = "mysql"
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
