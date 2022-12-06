output "bck_avd_host_ids" {
  value = [for i in azurerm_windows_virtual_machine.avd_vm : i.id]
}

output "bck_avd_hosts_location" {
  value = [for i in azurerm_windows_virtual_machine.avd_vm : i.location]  
}
  
output "bck_avd_hosts" {
  value = azurerm_windows_virtual_machine.avd_vm
  sensitive = false
}