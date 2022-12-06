output "scripts_account" {
  value = azurerm_storage_account.scripts
}
output "storage_account" {
  value = azurerm_storage_account.storage
}

output "setup-sql" {
  value = azurerm_storage_blob.setup-sql
}
output "setup-web" {
  value = azurerm_storage_blob.setup-web
}

output "random_id" {
  value = random_string.random.id
}

output "fileshares" {
  value = local.fileshares
}

output "test_enabled_client_accounts" {
  value = local.test_enabled_client_accounts
}


# output "setup_host_template" { value = data.template_file.setup-host}
output "setup_host_blob" { value = azurerm_storage_blob.setup_host}

output "import_share_url" { value = azurerm_storage_share.import.url }
output "import_share_user" { value = "localhost\\${azurerm_storage_account.storage.name}"}
output "import_share_pass" { 
  value = azurerm_storage_account.storage.primary_access_key
  sensitive = true
 }
output "import_share_account_name" { value = azurerm_storage_account.storage.name }

output "reports_share_url" { value = azurerm_storage_share.reports.url }
output "reports_share_user" { value = "localhost\\${azurerm_storage_account.storage.name}"}
output "reports_share_pass" { 
  value = azurerm_storage_account.storage.primary_access_key
  sensitive = true
 }
output "reports_share_account_name" { value = azurerm_storage_account.storage.name }