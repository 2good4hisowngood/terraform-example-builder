output "import_share_url" { value = module.storage.import_share_url }
output "import_share_user" { value = module.storage.import_share_user }
output "import_share_pass" {
  value     = module.storage.import_share_pass
  sensitive = true
}
output "import_share_account_name" { value = module.storage.import_share_account_name }



output "reports_share_url" { value = module.storage.reports_share_url }
output "reports_share_user" { value = module.storage.reports_share_user }
output "reports_share_pass" {
  value     = module.storage.reports_share_pass
  sensitive = true
}
output "reports_share_account_name" { value = module.storage.reports_share_account_name }