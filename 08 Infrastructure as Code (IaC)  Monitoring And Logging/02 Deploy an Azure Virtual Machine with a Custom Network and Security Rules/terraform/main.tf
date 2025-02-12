provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg-dev2025"
    storage_account_name = "tfstatestorage12345dev"
    container_name       = "tfstate-container"
    key                 = "terraform.tfstate"
  }
}

module "networking" {
  source              = "./modules/networking"
  location            = var.location
  resource_group_name = var.resource_group_name
}

module "security" {
  source              = "./modules/security"
  location            = var.location
  resource_group_name = var.resource_group_name
  security_group_name = "custom-nsg"
  allowed_ssh_ip      = var.allowed_ssh_ip
}

module "compute" {
  source              = "./modules/compute"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.networking.subnet_id
  public_ip_id        = module.networking.public_ip_id
  nsg_id              = module.security.nsg_id
  ssh_public_key      = var.ssh_public_key
}
