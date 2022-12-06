resource "azuread_group" "aad_group" {
  display_name     = var.aad_group_name
  security_enabled = true

  # This set is the object_id of each user in the client user csv.
  members = toset([for user in azuread_user.client_users : user.object_id])
}

resource "azuread_group" "app_grp_aad_group" {
  for_each =        local.app_group_config_mapping
  display_name     = "${var.client_name}_avd_${each.value.application_group}"
  # owners           = [data.azuread_client_config.current.object_id]
  security_enabled = true

  members = each.value.members
}

# Assign each app group aad group to the desktop virtualization user role
# in the respective application group.
resource "azurerm_role_assignment" "avd_app_group_users" {
  for_each = {
    for app_grp in var.application_groups : "${app_grp.name}" => app_grp
  }
  scope              = azurerm_virtual_desktop_application_group.avdag[each.key].id # from applications.tf
  role_definition_id = data.azurerm_role_definition.desktop_user.id
  principal_id       = each.key == "base" ? azuread_group.aad_group.object_id : azuread_group.app_grp_aad_group[each.key].object_id

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

