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
