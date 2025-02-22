variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "location" {
  description = "The Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the Azure resource group"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block for allowed SSH access"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "allowed_ssh_ip" {
  description = "CIDR block allowed for SSH access"
  type        = string
}

variable "load_balancer_ip" {
  type        = string
  description = "The public IP of the Load Balancer"
  default     = "0.0.0.0"
}

