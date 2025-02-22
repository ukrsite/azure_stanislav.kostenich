resource "azurerm_virtual_network" "vnet" {
  name                = "custom-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "custom-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "vm-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"  # Change from "Dynamic" to "Static"
  sku                 = "Standard" # Keep it as Standard
}