################################
#
# Reports storage
#
###############################

resource "azurerm_storage_share" "reports" {
  name                 = "reports"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = "50"

}

resource "azurerm_storage_share_directory" "reports" {
  name                 = "reports"
  share_name           = azurerm_storage_share.reports.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share.reports
  ]
}

resource "azurerm_storage_share_directory" "custom_reports" {
  name                 = "reports/custom_reports"
  share_name           = azurerm_storage_share.reports.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share.reports
  ]
}


################################
#
# Users csv storage
#
###############################

resource "azurerm_storage_container" "users_csv" {
  name                  = "users"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}