resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                = var.vmss_name
  location            = var.location
  resource_group_name = var.resource_group_name
  zones               = ["1", "2"]  # High availability
  sku                 = "Standard_B1ms"
  instances           = 2  

  admin_username      = "azureuser"
  admin_password      = "YourStrongPassword123!"
  disable_password_authentication = false

  upgrade_mode = "Manual"

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    echo "Sample Website" > /var/www/html/index.html
    systemctl start apache2
    systemctl enable apache2
  EOT
  )

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 30
  }

  network_interface {
    name    = "vmss-nic"
    primary = true

    ip_configuration {
      name      = "internal"
      subnet_id = var.subnet_id
      primary   = true
      load_balancer_backend_address_pool_ids = [var.backend_pool_id]
    }
  }

  tags = {
    environment = "production"
  }
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss-autoscale"
  resource_group_name = var.resource_group_name
  location            = var.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.vmss.id

  profile {
    name = "default"

    capacity {
      default = 2
      minimum = 2
      maximum = 3
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "GreaterThan"
        threshold          = 70
        time_window        = "PT5M" # Example: 5 minutes
        time_grain         = "PT1M" # Example: 1 minute
        time_aggregation   = "Average" # Example: Average aggregation
        statistic          = "Average" # Example: Average statistic
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT300S"  # Correct format
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.vmss.id
        operator           = "LessThan"
        threshold          = 30
        time_window        = "PT5M" # Example: 5 minutes
        time_grain         = "PT1M" # Example: 1 minute
        time_aggregation   = "Average" # Example: Average aggregation
        statistic          = "Average" # Example: Average statistic
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = 1
        cooldown  = "PT300S"  # Correct format
      }
    }
  }
}



