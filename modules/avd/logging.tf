

locals {
  avd_rg_name = "${var.primary_region}-avd-rg"
}

# data "azurerm_log_analytics_workspace" "regional" {
#   name                = "${var.primary_region}-avd"
#   resource_group_name = local.avd_rg_name
# }

resource "null_resource" "logging_ready" {
  
  depends_on = [
    azurerm_virtual_desktop_workspace.primary,
    azurerm_virtual_desktop_host_pool.pooledbreadthfirst
  ]
}

#########################
#
# Hostpool Logging
# Commented out as a new policy should handle this
#########################


# data "azurerm_monitor_diagnostic_categories" "hostpools" {
#   resource_id = azurerm_virtual_desktop_host_pool.pooledbreadthfirst.id
# }

# resource "azurerm_monitor_diagnostic_setting" "hostpools" {
#   name                       = "hostpools"
#   target_resource_id         = data.azurerm_monitor_diagnostic_categories.hostpools.resource_id
#   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.regional.id
#   # eventhub_name                  = azurerm_eventhub.primary.name
#   # eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.example.id
#   # storage_account_id = azurerm_storage_account.log_anal.id

#   dynamic "log" {
#     for_each = data.azurerm_monitor_diagnostic_categories.hostpools.logs
#     content {
#       category = log.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }
#   dynamic "metric" {
#     for_each = data.azurerm_monitor_diagnostic_categories.hostpools.metrics

#     content {
#       category = metric.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }

#   depends_on = [
#     null_resource.logging_ready,
#     azurerm_virtual_desktop_host_pool.pooledbreadthfirst
#   ]
# }

#########################
#
# workspace Logging
#
#########################

# data "azurerm_monitor_diagnostic_categories" "workspace" {
#   resource_id = azurerm_virtual_desktop_workspace.primary.id
# }

# resource "azurerm_monitor_diagnostic_setting" "workspace" {
#   name                       = "workspace"
#   target_resource_id         = data.azurerm_monitor_diagnostic_categories.workspace.resource_id
#   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.regional.id
#   # eventhub_name                  = azurerm_eventhub.primary.name
#   # eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.example.id
#   # storage_account_id = azurerm_storage_account.log_anal.id

#   dynamic "log" {
#     for_each = data.azurerm_monitor_diagnostic_categories.workspace.logs
#     content {
#       category = log.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }
#   dynamic "metric" {
#     for_each = data.azurerm_monitor_diagnostic_categories.workspace.metrics

#     content {
#       category = metric.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }

#   depends_on = [
#     null_resource.logging_ready,
#     azurerm_virtual_desktop_workspace.primary
#   ]
# }

#########################
#
# Recovery Vault Logging
#
#########################

# data "azurerm_resources" "recovery" {
#   type = "Microsoft.RecoveryServices/vaults"

#   required_tags = {
#     client = var.client_name
#   }
# }

# data "azurerm_monitor_diagnostic_categories" "recovery" {
#   count       = length(data.azurerm_resources.recovery.resources)
#   resource_id = data.azurerm_resources.recovery.resources[count.index].id
#   # resource_id = azurerm_recovery_services_vault.rv1.id
# }


# resource "azurerm_monitor_diagnostic_setting" "recovery" {
#   count                          = length(data.azurerm_monitor_diagnostic_categories.recovery)
#   name                           = "recovery"
#   target_resource_id             = data.azurerm_monitor_diagnostic_categories.recovery[count.index].resource_id
#   log_analytics_workspace_id     = data.azurerm_log_analytics_workspace.regional.id
#   log_analytics_destination_type = "AzureDiagnostics"
#   # eventhub_name                  = azurerm_eventhub.primary.name
#   # eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.example.id
#   # storage_account_id = azurerm_storage_account.log_anal.id

#   dynamic "log" {
#     for_each = data.azurerm_monitor_diagnostic_categories.recovery[count.index].logs
#     content {
#       category = log.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }
#   dynamic "metric" {
#     for_each = data.azurerm_monitor_diagnostic_categories.recovery[count.index].metrics

#     content {
#       category = metric.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }

#   depends_on = [
#     null_resource.logging_ready,
#     azurerm_recovery_services_vault.rv1,
#     azurerm_recovery_services_vault.rv2
#   ]
# }


#########################
#
# Storage Logging
#
#########################

# data "azurerm_resources" "storage" {
#   type = "Microsoft.Storage/storageAccounts"

#   required_tags = {
#     type   = "storage"
#     client = var.client_name
#   }
# }

# data "azurerm_monitor_diagnostic_categories" "storage" {
#   count       = length(data.azurerm_resources.storage.resources)
#   resource_id = data.azurerm_resources.storage.resources[count.index].id
# }


# resource "azurerm_monitor_diagnostic_setting" "storage" {
#   count                      = length(data.azurerm_monitor_diagnostic_categories.storage)
#   name                       = "storage"
#   target_resource_id         = data.azurerm_monitor_diagnostic_categories.storage[count.index].resource_id
#   log_analytics_workspace_id = data.azurerm_log_analytics_workspace.regional.id
#   # eventhub_name                  = azurerm_eventhub.primary.name
#   # eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.example.id
#   # storage_account_id = azurerm_storage_account.log_anal.id

#   dynamic "log" {
#     for_each = data.azurerm_monitor_diagnostic_categories.storage[count.index].logs
#     content {
#       category = log.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }
#   dynamic "metric" {
#     for_each = data.azurerm_monitor_diagnostic_categories.storage[count.index].metrics

#     content {
#       category = metric.key

#       retention_policy {
#         enabled = false
#         days    = 90
#       }
#     }
#   }

#   depends_on = [
#     null_resource.logging_ready
#   ]
# }