variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "9a6ae428-d8c3-44fe-bdf2-4e08593901a0"
}

variable "resource_group_name" {
  description = "Name of the existing Azure resource group"
  type        = string
  default     = "terraform-rg-dev2025"
}

variable "location" {
  description = "Azure region where resources are deployed"
  type        = string
  default     = "East US"
}

variable "storage_account_name" {
  description = "Azure Storage Account name for Terraform state"
  type        = string
  default     = "tfstatestorage12345dev"
}

variable "container_name" {
  description = "Azure Storage Container name for Terraform state"
  type        = string
  default     = "tfstate-container"
}

