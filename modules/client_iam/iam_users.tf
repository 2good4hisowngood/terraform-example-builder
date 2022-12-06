data "http" "csv_data" {
  url = var.csv_file_path
}

############
# Import the users into AAD
############
resource "azuread_user" "client_users" {
  for_each              = local.users_map
  user_principal_name   = "${each.value.user_name}@${var.domain_name}"
  display_name          = "${upper(var.client_name)} ${each.value.base_data.first_name} ${each.value.base_data.last_name}"
  password              = each.value.password
  other_mails           = [each.value.base_data.email]
  force_password_change = true
  usage_location        = "US"
  account_enabled       = each.value.account_enabled
}
