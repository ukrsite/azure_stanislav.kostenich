provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-rg-dev2025"
    storage_account_name = "tfstatestorage12345dev"
    container_name       = "tfstate-container"
    key                  = "terraform.tfstate"
  }
}

module "security" {
  source              = "./modules/security"
  nsg_name            = "my-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  allowed_ssh_cidr    = var.allowed_ssh_ip
  subnet1_id          = module.networking.subnet1_id
  subnet2_id          = module.networking.subnet2_id
}

module "networking" {
  source                 = "./modules/networking"
  vnet_name              = "my-vnet"
  location               = var.location
  resource_group_name    = var.resource_group_name
  address_space          = ["10.0.0.0/16"]
  subnet1_name           = "subnet1"
  subnet1_address_prefix = "10.0.1.0/24"
  subnet2_name           = "subnet2"
  subnet2_address_prefix = "10.0.2.0/24"
}

module "loadbalancer" {
  source              = "./modules/load_balancer"
  lb_name             = "my-lb"
  location            = var.location
  resource_group_name = var.resource_group_name
  public_ip_id        = module.networking.public_ip_id
}

module "compute" {
  source              = "./modules/compute"
  vmss_name           = "my-vmss"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = module.networking.subnet1_id
  backend_pool_id     = module.loadbalancer.backend_pool_id
  ssh_public_key      = var.ssh_public_key
  load_balancer_ip    = module.loadbalancer.public_ip
}
