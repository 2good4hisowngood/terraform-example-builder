data "azurerm_role_definition" "desktop_user" { # access an existing built-in role
  name = "Desktop Virtualization User"
}

#################
# client share rbac
#################
data "azurerm_role_definition" "storage_role" {
  name = "Storage File Data SMB Share Contributor"
}

resource "azurerm_role_assignment" "af_role" {
  scope              = var.storage_account_id
  role_definition_id = data.azurerm_role_definition.storage_role.id
  principal_id       = azuread_group.aad_group.id

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

