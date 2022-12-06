################################
#
# import storage
#
###############################

resource "azurerm_storage_share" "import" {
  name                 = "import"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = "300"
}

# Directories in Import share for App, SQL and Web servers
resource "azurerm_storage_share_directory" "app" {
  name                 = "app"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "sql" {
  name                 = "sql"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "_210" {
  name                 = "sql/210"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share_directory.sql
  ]
}

resource "azurerm_storage_share_directory" "web" {
  name                 = "web"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "appScheduler" {
  name                 = "web/appScheduler"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share_directory.web
  ]
}

resource "azurerm_storage_share_directory" "appWebServices" {
  name                 = "web/appWebServices"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share_directory.web
  ]
}

# Databases

resource "azurerm_storage_share_directory" "dbs" {
  name                 = "databases"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name
}

resource "azurerm_storage_share_directory" "appdb" {
  name                 = "databases/appdb"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share_directory.dbs
  ]
}

resource "azurerm_storage_share_directory" "appdb2" {
  name                 = "databases/appdb2"
  share_name           = azurerm_storage_share.import.name
  storage_account_name = azurerm_storage_account.storage.name

  depends_on = [
    azurerm_storage_share_directory.dbs
  ]
}