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
