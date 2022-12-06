# resource "null_resource" "backup_ready" {
  
#   depends_on = [
#     azurerm_virtual_machine_extension.setup-web,
#   ]
# }

resource "azurerm_backup_protected_vm" "web" {
  count = var.web_count
  resource_group_name = var.rg1.name
  recovery_vault_name = var.rv1.name
  source_vm_id        = azurerm_virtual_machine.web[count.index].id
  backup_policy_id    = var.bp1.id

  depends_on = [
    azurerm_virtual_machine.web,
    var.rv1,
    azurerm_virtual_machine_extension.setup-web
  ]
}

# SQL Failover
resource "azurerm_site_recovery_replicated_vm" "web-replication" {
  count = var.web_count
  name                                      = "web-replication"
  resource_group_name                       = var.rg2.name
  recovery_vault_name                       = var.rv2.name
  source_vm_id                              = azurerm_virtual_machine.web[count.index].id
  recovery_replication_policy_id            = var.site_replication_policy.id
  source_recovery_protection_container_name = var.recovery_container_primary.name
  source_recovery_fabric_name               = var.fabric_primary.name

  target_resource_group_id                = var.rg2.id
  target_recovery_fabric_id               = var.fabric_secondary.id
  target_recovery_protection_container_id = var.recovery_container_secondary.id
  target_network_id                       = var.vnet2.id

  managed_disk {
    disk_id                    = azurerm_virtual_machine.web[count.index].storage_os_disk[0].managed_disk_id
    staging_storage_account_id = var.recovery_storage_cache.id
    target_resource_group_id   = var.rg2.id
    target_disk_type           = "Premium_LRS"
    target_replica_disk_type   = "Premium_LRS"
  }

  # managed_disk {
  #   disk_id                    = azurerm_virtual_machine.web[count.index].storage_data_disk[0].managed_disk_id
  #   staging_storage_account_id = var.recovery_storage_cache.id
  #   target_resource_group_id   = var.rg2.id
  #   target_disk_type           = "Premium_LRS"
  #   target_replica_disk_type   = "Premium_LRS"
  # }

  network_interface {
    source_network_interface_id = azurerm_network_interface.web[count.index].id
    target_subnet_name          = azurerm_subnet.web2.name
  }

  depends_on = [
    azurerm_virtual_machine_extension.domain_join-web,
    azurerm_backup_protected_vm.web
  ]
}