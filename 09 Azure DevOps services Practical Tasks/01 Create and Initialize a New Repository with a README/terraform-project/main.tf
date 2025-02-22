# Configure the Azure provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Backend configuration
terraform {
  backend "azurerm" {
    resource_group_name  = "StanislavKostenich"
    storage_account_name = "tfstatestorage2025dev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}