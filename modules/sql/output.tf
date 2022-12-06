output "sql" {
  value = local.sql_vms
  sensitive = false
}

locals {
    sql_vms = [
        for vm in azurerm_virtual_machine.sql : {
            name = vm.name
            id = vm.id
            location = vm.location
        }
    ]
}