provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_storage_account" "storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

terraform {
  backend "azurerm" {
    resource_group_name   = "terraform-rg-dev2025"
    storage_account_name  = "tfstatestorage12345dev"
    container_name        = "tfstate-container"
    key                   = "terraform.tfstate"
  }
}
