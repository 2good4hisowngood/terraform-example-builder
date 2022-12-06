# resource "azurerm_monitor_diagnostic_setting" "autoscale" {
#   name               = "AutoScale"
#   target_resource_id = azurerm_virtual_desktop_scaling_plan.weekdays.id
#   storage_account_id = azurerm_storage_account.storage.id

#   log {
#     category = "Autoscale"
#     enabled  = true

#     retention_policy {
#       enabled = false
#     }
#   }
# }