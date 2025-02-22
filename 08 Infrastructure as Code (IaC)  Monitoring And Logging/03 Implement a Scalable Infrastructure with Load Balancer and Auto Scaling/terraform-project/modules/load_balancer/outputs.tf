output "backend_pool_id" {
  value = azurerm_lb_backend_address_pool.lb_backend_pool.id
}

output "load_balancer_ip" {
  value = azurerm_lb.load_balancer.frontend_ip_configuration[0].public_ip_address_id
}

output "public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

