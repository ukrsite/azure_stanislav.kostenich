variable "subscription_id" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "container_name" {
  type = string
}

variable "key" {
  type = string
}

variable "app_service_plan_name" {
  description = "The name of the App Service Plan"
  default     = "MySampleAppPlan"
}

variable "web_app_name" {
  description = "The name of the Web App"
  default     = "devWebApp2025"
}

variable "sql_server_name" {
  description = "The name of the SQL Server"
  default     = "mysamplesqlserver2025"
}

variable "sql_database_name" {
  description = "The name of the SQL Database"
  default     = "mysampledatabase"
}

variable "sql_admin_username" {
  description = "The admin username for the SQL Server"
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "The admin password for the SQL Server"
  sensitive   = true
}