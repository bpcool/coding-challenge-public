variable "location" {
  type    = string
  default = "centralus"
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
