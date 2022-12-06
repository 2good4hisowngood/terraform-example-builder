resource "null_resource" "backup_ready" {
  
  depends_on = [
    azurerm_virtual_desktop_workspace.primary,
    azurerm_virtual_desktop_host_pool.pooledbreadthfirst
  ]
}

resource "azurerm_recovery_services_vault" "rv1" {
  name                = "${var.client_name}-recovery-vault1"
  location            = var.rg1.location
  resource_group_name = var.rg1.name
  sku                 = "Standard"

  soft_delete_enabled = var.soft_delete

  tags = merge(local.default_tags, { type = "recovery" })
}

resource "azurerm_recovery_services_vault" "rv2" {
  name                = "${var.client_name}-recovery-vault2"
  location            = var.rg2.location
  resource_group_name = var.rg2.name
  sku                 = "Standard"

  soft_delete_enabled = var.soft_delete

  tags = merge(local.default_tags, { type = "recovery" })
}

resource "time_sleep" "vaults_to_policies" {
  create_duration = "60s"

  triggers = {
    "rv1" = azurerm_recovery_services_vault.rv1.name
    "rv2" = azurerm_recovery_services_vault.rv2.name
  }

  depends_on = [
    azurerm_recovery_services_vault.rv1,
    azurerm_recovery_services_vault.rv2
  ]
}

resource "azurerm_backup_policy_vm" "bp1" {
  name                = "${var.client_name}-recovery-vault1-policy"
  resource_group_name = var.rg1.name
  recovery_vault_name = time_sleep.vaults_to_policies.triggers["rv1"]

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "07:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 9
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 5
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }

  depends_on = [
    azurerm_recovery_services_vault.rv1
  ]
}

resource "azurerm_backup_policy_vm" "bp2" {
  name                = "${var.client_name}-recovery-vault2-policy"
  resource_group_name = var.rg2.name
  recovery_vault_name = time_sleep.vaults_to_policies.triggers["rv2"]

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "07:00"
  }

  retention_daily {
    count = 30
  }

  retention_weekly {
    count    = 4
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 9
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 5
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }

  depends_on = [
    azurerm_recovery_services_vault.rv2
  ]
}

######################
# Site Recovery Settings
######################
# Storage Account for cache data
#tfsec:ignore:azure-storage-queue-services-logging-enabled
resource "azurerm_storage_account" "cache" {
  name                     = "primaryrecoverycache${var.random_id}"
  location                 = var.rg1.location
  resource_group_name      = var.rg1.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Policy
resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = "policy"
  resource_group_name                                  = var.rg2.name
  recovery_vault_name                                  = time_sleep.vaults_to_policies.triggers["rv2"]
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

# Site Recovery Fabric
resource "azurerm_site_recovery_fabric" "primary" {
  name                = "${var.client_name}-fabric"
  resource_group_name = var.rg2.name
  recovery_vault_name = azurerm_recovery_services_vault.rv2.name
  location            = var.rg1.location

  depends_on = [
    azurerm_recovery_services_vault.rv2
    # This also needs all vms using it to be off before it can be destroyed
    # They still destroy, but it ends up erroring erroneously causing a crash and preventing a successful destroy run.
# maybe...
  ]
}

resource "azurerm_site_recovery_fabric" "secondary" {
  name                = "secondary-fabric"
  resource_group_name = var.rg2.name
  recovery_vault_name = azurerm_recovery_services_vault.rv2.name
  location            = var.rg2.location

  depends_on = [
    azurerm_recovery_services_vault.rv2
  ]
}

# Site Recovery Protection Container
resource "azurerm_site_recovery_protection_container" "primary" {
  name                 = "${var.client_name}-protection-container"
  resource_group_name  = var.rg2.name
  recovery_vault_name  = azurerm_recovery_services_vault.rv2.name
  recovery_fabric_name = azurerm_site_recovery_fabric.primary.name

  depends_on = [
    azurerm_recovery_services_vault.rv2,
    azurerm_site_recovery_fabric.primary
  ]
}

resource "azurerm_site_recovery_protection_container" "secondary" {
  name                 = "secondary-protection-container"
  resource_group_name  = var.rg2.name
  recovery_vault_name  = azurerm_recovery_services_vault.rv2.name
  recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name

  depends_on = [
    azurerm_recovery_services_vault.rv2,
    azurerm_site_recovery_fabric.secondary,
    azurerm_site_recovery_protection_container.primary
  ]
}

resource "azurerm_site_recovery_protection_container_mapping" "container-mapping" {
  name                                      = "container-mapping"
  resource_group_name                       = var.rg2.name
  recovery_vault_name                       = azurerm_recovery_services_vault.rv2.name
  recovery_fabric_name                      = azurerm_site_recovery_fabric.primary.name
  recovery_source_protection_container_name = azurerm_site_recovery_protection_container.primary.name
  recovery_target_protection_container_id   = azurerm_site_recovery_protection_container.secondary.id
  recovery_replication_policy_id            = azurerm_site_recovery_replication_policy.policy.id

  depends_on = [
    azurerm_recovery_services_vault.rv2,
    azurerm_site_recovery_fabric.secondary,
    azurerm_storage_account.cache,
    azurerm_site_recovery_protection_container.secondary,
    azurerm_site_recovery_replication_policy.policy
  ]
}

resource "azurerm_site_recovery_network_mapping" "network-mapping" {
  name                        = "network-mapping"
  resource_group_name         = var.rg2.name
  recovery_vault_name         = azurerm_recovery_services_vault.rv2.name
  source_recovery_fabric_name = azurerm_site_recovery_fabric.primary.name
  target_recovery_fabric_name = azurerm_site_recovery_fabric.secondary.name
  source_network_id           = azurerm_virtual_network.vnet1.id
  target_network_id           = azurerm_virtual_network.vnet2.id
}

######################
# Storage Account Backups
######################
# data "azurerm_resources" "test_enabled_client_accounts" {
#   type = "Microsoft.Storage/storageAccounts"

#   required_tags = {
#     client = "${var.client_name}"
#   }
# }

resource "null_resource" "test_enabled_client_accounts" {
  count = local.test_enabled ? 0 : length(var.test_enabled_client_accounts)
  triggers = {
    "key" = var.test_enabled_client_accounts[count.index].id
  }
}

resource "azurerm_backup_container_storage_account" "test_enabled_client_accounts" {
  count               = length(null_resource.test_enabled_client_accounts)
  resource_group_name = var.rg1.name
  recovery_vault_name = azurerm_recovery_services_vault.rv1.name
  storage_account_id  = null_resource.test_enabled_client_accounts[count.index].triggers.key

  depends_on = [
    null_resource.logging_ready
  ]
}

# resource "azurerm_backup_container_storage_account" "storage" {
#   # count           = local.test_enabled ? 0 : 1
#   resource_group_name = var.rg1.name
#   recovery_vault_name = azurerm_recovery_services_vault.rv1.name
#   storage_account_id  = azurerm_storage_account.storage.id
# }

# resource "azurerm_backup_container_storage_account" "scripts" {
#   for_each = null_resource.test_enabled
#   resource_group_name = var.rg1.name
#   recovery_vault_name = azurerm_recovery_services_vault.rv1.name
#   storage_account_id  = azurerm_storage_account.scripts.id
# }

######################
# File Share Backups
######################

resource "null_resource" "test_enabled_shares" {
  count = local.test_enabled ? 0 : length(var.fileshares)
  triggers = {
    "key" = var.fileshares[count.index].name

  }
}

resource "azurerm_backup_protected_file_share" "test_enabled_shares" {
  count                     = length(null_resource.test_enabled_shares)
  resource_group_name       = var.rg1.name
  recovery_vault_name       = azurerm_recovery_services_vault.rv1.name
  source_storage_account_id = var.storage_account.id
  source_file_share_name    = null_resource.test_enabled_shares[count.index].triggers.key
  backup_policy_id          = azurerm_backup_policy_file_share.policy.id

  depends_on = [
    azurerm_backup_container_storage_account.test_enabled_client_accounts,
    null_resource.logging_ready
  ]
}

resource "azurerm_backup_policy_file_share" "policy" {
  name                = "tfex-recovery-vault-policy"
  resource_group_name = var.rg1.name
  recovery_vault_name = time_sleep.vaults_to_policies.triggers["rv1"]

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "07:00"
  }

  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 7
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 7
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 7
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}

