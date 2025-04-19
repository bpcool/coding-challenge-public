
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

# variable "network_security_group_id" {
#   type = string
# }

variable "mysql_admin_username" {
  type = string
}

variable "mysql_admin_password" {
  type      = string
  sensitive = true
}

