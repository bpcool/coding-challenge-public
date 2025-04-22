# ------------------------
# Variables
# ------------------------
variable "location" {
  type    = string
}

variable "resource_group_name" {
  type    = string
}

variable "mysql_admin_password" {
   type    = string
   sensitive   = true
}

variable "log_analytics_workspace_id" {
  type = string
}

