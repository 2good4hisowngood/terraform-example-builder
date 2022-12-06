resource "azurerm_network_interface" "web" {
  count = var.web_count
  name                = "${var.client_name}-prod-web-nic"
  location            = var.rg1.location
  resource_group_name = var.rg1.name

  ip_configuration {
    name                          = "web"
    subnet_id                     = azurerm_subnet.web.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.default_tags
}

resource "azurerm_virtual_machine" "web" {
  count = var.web_count
  name                  = "${var.client_name}-web"
  location              = var.rg1.location
  resource_group_name   = var.rg1.name
  network_interface_ids = ["${azurerm_network_interface.web[count.index].id}"]
  vm_size               = var.web_vm_size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.client_name}web-OsDisk-1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name              = "${var.client_name}web-DataDisk-1"
    caching           = "ReadWrite"
    create_option     = "Empty"
    managed_disk_type = "Premium_LRS"
    lun               = "2"
    disk_size_gb      = "127"
  }

  os_profile {
    computer_name  = "${var.client_name}-web"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = "true"
    timezone           = var.timezone
  }

  tags = merge(local.default_tags, local.vm_tags, local.sql_web_tags, var.web_tags)

  lifecycle {
    ignore_changes = [
      boot_diagnostics,
      identity
    ]
  }
}


# Extentions

resource "azurerm_virtual_machine_extension" "domain_join-web" {
  count = var.web_count
  name                       = "domain-join-web"
  virtual_machine_id         = azurerm_virtual_machine.web[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.ou_path}",
      "User": "${var.domain_user_upn}@${var.domain_name}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.admin_password}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

resource "azurerm_virtual_machine_extension" "setup-web" {
  count = var.web_count
  name                       = "${var.client_name}-setup-web"
  virtual_machine_id         = azurerm_virtual_machine.web[count.index].id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = "true"

  protected_settings = <<PROTECTED_SETTINGS
    {
      "storageAccountName": "${var.scripts_account.name}",
      "storageAccountKey": "${var.scripts_account.primary_access_key}"
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
      {
          "fileUris": ["https://${var.scripts_account.name}.blob.core.windows.net/scripts/setup-web.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file setup-web.ps1"      
      }
  SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.domain_join-web,
  ]
}

resource "azurerm_virtual_machine_extension" "AzureMonitorWindowsAgent_web" {
  count = var.web_count
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_virtual_machine.web[count.index].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  # automatic_upgrade_enabled = true

  depends_on = [
    azurerm_virtual_machine_extension.setup-web
  ]
}

resource "azurerm_virtual_machine_extension" "VMDiagnosticsSettings_web" {
  count = var.web_count
  name                       = "Microsoft.Insights.VMDiagnosticsSettings"
  virtual_machine_id         = azurerm_virtual_machine.web[count.index].id
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "IaaSDiagnostics"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = "true"
  # automatic_upgrade_enabled = true

  settings           = <<SETTINGS
    {
      "xmlCfg": "${base64encode(templatefile("${path.module}/scripts/wadcfgxml.tmpl", { vmid = azurerm_virtual_machine.web[count.index].id }))}",
      "storageAccount": "${var.scripts_account.name}"
    }
SETTINGS
  protected_settings = <<PROTECTEDSETTINGS
    {
      "storageAccountName": "${var.scripts_account.name}",
      "storageAccountKey": "${var.scripts_account.primary_access_key}",
      "storageAccountEndPoint": "https://core.windows.net"
    }
PROTECTEDSETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.AzureMonitorWindowsAgent_web
  ]
}
