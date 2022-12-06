resource "azurerm_network_interface" "sql" {
  count = var.sql_count
  name                = "${var.client_name}-prod-sql-nic"
  location            = var.rg1.location
  resource_group_name = var.rg1.name

  ip_configuration {
    name                          = "sql"
    subnet_id                     = azurerm_subnet.sql.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = local.default_tags
}

resource "azurerm_virtual_machine" "sql" {
  count = var.sql_count
  name                  = "${var.client_name}-sql"
  location              = var.rg1.location
  resource_group_name   = var.rg1.name
  network_interface_ids = ["${azurerm_network_interface.sql[count.index].id}"]
  vm_size = var.sql_vm_size

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftSQLServer"
    offer     = "SQL2019-WS2022"
    sku       = "Standard"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.client_name}sql-OsDisk-1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_data_disk {
    name              = "${var.client_name}sql-DataDisk-1"
    caching           = "ReadWrite"
    create_option     = "Empty"
    managed_disk_type = "Premium_LRS"
    lun               = "2"
    disk_size_gb      = "1024"
  }

  os_profile {
    computer_name  = "${var.client_name}-sql"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = "true"
    timezone           = var.timezone
  }

  tags = merge(local.default_tags, local.vm_tags, local.sql_web_tags, var.sql_tags)

  lifecycle {
    ignore_changes = [
      boot_diagnostics,
      identity,
      storage_image_reference
    ]
  }
}

# Extentions

resource "azurerm_virtual_machine_extension" "first-domain_join_sql" {
  count = var.sql_count
  name                       = "domain-join-sql"
  virtual_machine_id         = azurerm_virtual_machine.sql[count.index].id
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

  depends_on = [
    var.peering_out,
    var.peering_in,
  ]
}

resource "time_sleep" "sql_domain_join_reboot" {
  count = var.sql_count
  create_duration = "600s"
  destroy_duration = "5s"

  triggers = {
    virtual_machine_id = azurerm_virtual_machine_extension.first-domain_join_sql[count.index].virtual_machine_id
  }

  depends_on = [
    azurerm_virtual_machine_extension.first-domain_join_sql
  ] 
}


resource "azurerm_mssql_virtual_machine" "second-azurerm_sqlvmmanagement" {
  count = var.sql_count

  virtual_machine_id               = time_sleep.sql_domain_join_reboot[count.index].triggers.virtual_machine_id
  sql_license_type                 = "PAYG"
  sql_connectivity_port            = 1433
  sql_connectivity_type            = "PRIVATE"
  sql_connectivity_update_password = var.sql_connectivity_update_password
  sql_connectivity_update_username = var.sql_connectivity_update_username

  auto_patching {
    day_of_week                            = "Sunday"
    maintenance_window_duration_in_minutes = 60
    maintenance_window_starting_hour       = 2
  }

  storage_configuration {
    disk_type             = "NEW"  # (Required) The type of disk configuration to apply to the SQL Server. Valid values include NEW, EXTEND, or ADD.
    storage_workload_type = "OLTP" # (Required) The type of storage workload. Valid values include GENERAL, OLTP, or DW.

    # The storage_settings block supports the following:
    data_settings {
      default_file_path = "F:\\SQL\\${var.client_name}\\databases" # (Required) The SQL Server default path 
      luns              = [2]                        #azurerm_virtual_machine_data_disk_attachment.datadisk_attach[count.index].lun]
    }

    log_settings {
      default_file_path = "F:\\SQL\\${var.client_name}\\logs" # (Required) The SQL Server default path 
      luns              = [2]                       #azurerm_virtual_machine_data_disk_attachment.logdisk_attach[count.index].lun] # (Required) A list of Logical Unit Numbers for the disks.
    }
  }

  auto_backup {
    retention_period_in_days = 30
    storage_blob_endpoint = var.scripts_account.primary_blob_endpoint
    storage_account_access_key = var.scripts_account.primary_access_key    
  }

  depends_on = [
    azurerm_virtual_machine_extension.first-domain_join_sql
  ]
}

resource "time_sleep" "second-azurerm_sqlvmmanagement" {
  count = var.sql_count
  create_duration = "600s"
  destroy_duration = "5s"

  triggers = {
    virtual_machine_id = azurerm_mssql_virtual_machine.second-azurerm_sqlvmmanagement[count.index].virtual_machine_id
  }

  depends_on = [
    azurerm_mssql_virtual_machine.second-azurerm_sqlvmmanagement
  ] 
}


resource "azurerm_virtual_machine_extension" "third-setup-sql" {
  count = var.sql_count
  name                       = "${var.client_name}-setup-sql"
  virtual_machine_id         = time_sleep.second-azurerm_sqlvmmanagement[count.index].triggers.virtual_machine_id
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
          "fileUris": ["https://${var.scripts_account.name}.blob.core.windows.net/scripts/setup-sql.ps1"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted -file setup-sql.ps1 ${azurerm_virtual_machine.sql[count.index].name} ${var.client_name} ${var.smtp_key}"
      }
  SETTINGS

  depends_on = [
    azurerm_mssql_virtual_machine.second-azurerm_sqlvmmanagement
  ]
}
