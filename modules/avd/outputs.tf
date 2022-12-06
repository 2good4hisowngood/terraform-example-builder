
# for multiple modules

output "rg1" {
  value = var.rg1
}
output "rg2" {
  value = var.rg2
}
output "rv1" {
  value = azurerm_recovery_services_vault.rv1
}
output "rv2" {
  value = azurerm_recovery_services_vault.rv2
}
output "vnet1" {
  value = azurerm_virtual_network.vnet1  
}
output "vnet2" {
  value = azurerm_virtual_network.vnet2
}


# For IAM Module

output "azurerm_virtual_desktop_host_pool" {
  value = var.host_enabled ? azurerm_virtual_desktop_host_pool.pooledbreadthfirst.id : "/subscriptions/${var.subscription_id}/resourceGroups/${var.shared_name}-prod-rg1/providers/Microsoft.DesktopVirtualization/hostPools/${var.shared_name}-avdhp"
}
output "azurerm_virtual_desktop_workspace" {
  value = var.host_enabled ? azurerm_virtual_desktop_workspace.primary.id : "/subscriptions/${var.subscription_id}/resourceGroups/${var.shared_name}-prod-rg1/providers/Microsoft.DesktopVirtualization/workspaces/${var.shared_name}-workspace"
}


# For SQL module
output "peering_out" {
  value = azurerm_virtual_network_peering.out-primary
}
output "peering_in" {
  value = azurerm_virtual_network_peering.in-primary
}

output "bp1" {
  value = azurerm_backup_policy_vm.bp1
}

output "site_replication_policy" {
  value = azurerm_site_recovery_replication_policy.policy
}
output "recovery_container_primary" {
  value = azurerm_site_recovery_protection_container.primary
}
output "fabric_primary" {
  value = azurerm_site_recovery_fabric.primary
}
output "fabric_secondary" {
  value = azurerm_site_recovery_fabric.secondary
}
output "recovery_container_secondary" {
  value = azurerm_site_recovery_protection_container.secondary
}
output "recovery_storage_cache" {
  value = azurerm_storage_account.cache
}



