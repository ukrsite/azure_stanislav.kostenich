variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
}

variable "location" {
  default = "East US"
}

variable "aks_cluster_name" {
  default = "aks-prod-cluster"
}

variable "dns_prefix" {
  default = "aks-prod"
}

variable "node_count" {
  default = 3
}

variable "vm_size" {
  default = "Standard_D4s_v3"
}

variable "tenant_id" {}

variable "key_vault_name" {
  default = "akssecretsvault"
}

variable "log_workspace_name" {
  default = "aks-log-workspace"
}

