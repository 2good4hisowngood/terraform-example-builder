data "azurerm_shared_image" "app" {
  gallery_name        = var.image_gallery_name
  name                = var.app_image_name
  resource_group_name = var.app_image_resource_group_name
}

resource "random_string" "avd_vm" {
  count  = var.rdsh_count
  
  length = 8
  special = false
  upper = false
  
  keepers = {
    # Generate a new pet name each time we update the setup_host script
    source_content = "${var.setup_host_template}"
  }
}

resource "azurerm_network_interface" "avd_vm_nic" {
  count               = length(random_string.avd_vm)
  name                = "${var.client_name}-${random_string.avd_vm[count.index].id}-nic"
  resource_group_name = var.resource_group.name
  location            = var.primary_region

  ip_configuration {
    name                          = "${var.client_name}-${random_string.avd_vm[count.index].id}_config"
    subnet_id                     = var.subnet.id
    private_ip_address_allocation = "dynamic"
  }

  tags = local.default_tags
}

# data "azurerm_key_vault" "cert_vault" {
#   name                = var.msix_code_sign_key_vault_name
#   resource_group_name = var.msix_code_sign_key_vault_resource_group_name
# }

# data "azurerm_key_vault_certificate" "signing_cert" {
#   name         = var.msix_code_sign_key_vault_certificate_name
#   key_vault_id = data.azurerm_key_vault.cert_vault.id
# }

resource "azurerm_windows_virtual_machine" "avd_vm" {
  count                 = length(azurerm_network_interface.avd_vm_nic)
  name                  = "${var.client_name}-${random_string.avd_vm[count.index].id}"
  resource_group_name   = var.resource_group.name
  location              = var.primary_region
  size                  = var.avd_vm_size
  network_interface_ids = ["${azurerm_network_interface.avd_vm_nic.*.id[count.index]}"]
  provision_vm_agent    = true
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  timezone              = var.timezone

  os_disk {
    name                      = random_string.avd_vm[count.index].id
    caching                   = "ReadWrite"
    storage_account_type      = "Premium_LRS"
    write_accelerator_enabled = false
  }
  source_image_id = data.azurerm_shared_image.app.id

  # source_image_reference {
  #   publisher = "MicrosoftWindowsDesktop"
  #   offer     = "Windows-10"
  #   sku       = "win10-21h2-avd"
  #   version   = "latest"
  # }

  # secret {
  #   key_vault_id = data.azurerm_key_vault.cert_vault.id
  #   certificate {
  #     url = data.azurerm_key_vault_certificate.signing_cert.secret_id
  #     store  = "${var.msix_code_sign_key_vault_certificate_store}"
  #   }
  # }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [
    random_string.avd_vm
  ]

  tags = merge(local.default_tags, local.app_tags, { count = "${count.index + 1}" }, {disaster_recovery = "true" })

  lifecycle {
    ignore_changes = [
      boot_diagnostics,
      identity,
      source_image_id
    ]
  }
}

# Extensions


# This extension should activate last, as it registers the vm to the hostpool
resource "azurerm_virtual_machine_extension" "last_host_extension_hp_registration" {
  count                      = var.rdsh_count
  name                       = "${var.client_name}-${random_string.avd_vm[count.index].id}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  # automatic_upgrade_enabled = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_3-10-2021.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${var.hostpool.name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.hostpool_registration_token}"
    }
  }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }

  depends_on = [
    azurerm_virtual_machine_extension.sixth-vminsights_agent
  ]
}

resource "azurerm_virtual_machine_extension" "first-domain_join_extension" {
  count                      = var.rdsh_count
  name                       = "${var.client_name}-avd-${random_string.avd_vm[count.index].id}-domainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true
  # automatic_upgrade_enabled = true

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

# All extensions after domain join are placed after a wait time
# This prevents the reboot from domain join from affecting the extensions afterward.
resource "time_sleep" "domain_join_reboot" {
  count = length(azurerm_windows_virtual_machine.avd_vm)
  create_duration = "240s"
  destroy_duration = "5s"

  triggers = {
    name = "${random_string.avd_vm[count.index].id}"
    virtual_machine_id = azurerm_windows_virtual_machine.avd_vm[count.index].id
  }

  depends_on = [
    azurerm_virtual_machine_extension.first-domain_join_extension,
    random_string.avd_vm
  ] 
}

locals {
  testdetails = "${var.client_name}_#{Octopus.Environment.Name}"
  param1 = "${var.storage_account_name} ${var.storage_account_key} ${var.domain} ${var.aad_group_name} ${local.testdetails}"
  command = "powershell -ExecutionPolicy Unrestricted -file setup-host.ps1 ${local.param1}"
}

# Multiple scripts called by ./<scriptname referencing them in follow-up scripts
# https://web.archive.org/web/20220127015539/https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows
# https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/custom-script-windows#using-multiple-scripts
resource "azurerm_virtual_machine_extension" "second-custom_scripts" {
  count                      = var.rdsh_count
  name                       = "${time_sleep.domain_join_reboot[count.index].triggers.name}-setup-host"
  virtual_machine_id         = time_sleep.domain_join_reboot[count.index].triggers.virtual_machine_id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  protected_settings = <<PROTECTED_SETTINGS
    {
      "storageAccountName": "${var.scripts_account_name}",
      "storageAccountKey": "${var.scripts_account_key}"
    }
  PROTECTED_SETTINGS

  settings = <<SETTINGS
      {
          "fileUris": ["https://${var.scripts_account_name}.blob.core.windows.net/scripts/setup-host.ps1"],
          "commandToExecute": "${local.command}"
      } 
  SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.first-domain_join_extension,
    time_sleep.domain_join_reboot
  ]
}

# # Disabling, replaced by policy

# resource "azurerm_virtual_machine_extension" "third-dependency_agent_logging" {
#   count                      = var.rdsh_count
#   name                       = "DependencyAgentExtension"
#   virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
#   publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
#   type                       = "DependencyAgentWindows"
#   type_handler_version       = "9.10"
#   auto_upgrade_minor_version = false
#   automatic_upgrade_enabled  = true

#   depends_on = [
#     azurerm_virtual_machine_extension.second-custom_scripts
#   ]
# }

resource "azurerm_virtual_machine_extension" "fourth-windows_monitoring_agent" {
  count                      = var.rdsh_count
  name                       = "AzureMonitorWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = "true"
  # automatic_upgrade_enabled = true

  depends_on = [
    azurerm_virtual_machine_extension.second-custom_scripts
  ]
}

resource "azurerm_virtual_machine_extension" "fifth-VMDiagnosticsSettings_host" {
  count                      = var.rdsh_count
  name                       = "Microsoft.Insights.VMDiagnosticsSettings"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Azure.Diagnostics"
  type                       = "IaaSDiagnostics"
  type_handler_version       = "1.9"
  auto_upgrade_minor_version = "true"
  # automatic_upgrade_enabled = true

  settings           = <<SETTINGS
    {
      "xmlCfg": "${base64encode(templatefile("${var.xmlCfg}", { vmid = azurerm_windows_virtual_machine.avd_vm.*.id[count.index] }))}",
      "storageAccount": "${var.scripts_account_name}"
    }
SETTINGS
  protected_settings = <<PROTECTEDSETTINGS
    {
      "storageAccountName": "${var.scripts_account_name}",
      "storageAccountKey": "${var.scripts_account_key}",
      "storageAccountEndPoint": "https://core.windows.net"
    }
PROTECTEDSETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.fourth-windows_monitoring_agent
  ]
}

resource "azurerm_virtual_machine_extension" "sixth-vminsights_agent" {
  count                      = var.rdsh_count
  name                       = "GuestHealthWindowsAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.avd_vm.*.id[count.index]
  publisher                  = "Microsoft.Azure.Monitor.VirtualMachines.GuestHealth"
  type                       = "GuestHealthWindowsAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  # automatic_upgrade_enabled = true

  depends_on = [
    azurerm_virtual_machine_extension.fifth-VMDiagnosticsSettings_host
  ]
}