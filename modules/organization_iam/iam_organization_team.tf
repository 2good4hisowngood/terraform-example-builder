#################
# Admin rbac
#################
data "azurerm_role_definition" "desktop_user" { # access an existing built-in role
  name = "Desktop Virtualization User"
}

data "azurerm_role_definition" "admin_storage_role" {
  name = "Storage File Data SMB Share Elevated Contributor"
  # This is set in azurerm_role_assignment.admin_storage_role and admin_script_role
  # Both have the lifecycle ignore changes on with regards to this definition as the definition id changes regularly causing rebuilds of the roles.
}

data "azurerm_role_definition" "admin_script_role" {
  name = "Storage Blob Data Contributor"
}

data "azuread_group" "HostingAdmins" {
  display_name     = "HostingAdmins"
  security_enabled = true
}

resource "azurerm_role_assignment" "admin_storage_role" {
  scope              = var.storage_account_id
  role_definition_id = data.azurerm_role_definition.admin_storage_role.id
  principal_id       = data.azuread_group.HostingAdmins.id

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

resource "azurerm_role_assignment" "admin_script_role" {
  scope              = var.scripts_account_id
  role_definition_id = data.azurerm_role_definition.admin_script_role.id
  principal_id       = data.azuread_group.HostingAdmins.id

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

# Octopus Service Principal
# To give itself power over the storage accounts

data "azuread_service_principal" "octopus" {
  application_id = var.azureaccountClientID
}

resource "azurerm_role_assignment" "account1_write" {
  scope              = var.scripts_account_id
  role_definition_id = data.azurerm_role_definition.admin_script_role.id
  principal_id       = data.azuread_service_principal.octopus.id

  lifecycle {
    ignore_changes = [
      role_definition_id
    ]
  }
}

# This is to give Portal and DB team members Admin access to the client environments
# Come back here when you put in the auto-approval/employee access management piece

data "azuread_group" "portalsAdmins" {
  display_name     = "portalsAdmins"
  security_enabled = true
}

data "azuread_group" "dbsAdmins" {
  display_name     = "DbSolutions"
  security_enabled = true
}

resource "azuread_group" "portalsAdmins" {
  display_name = "${var.client_name}portalsAdmins"
  security_enabled = true
}

resource "azuread_group" "dbsAdmins" {
  display_name = "${var.client_name}dbsAdmins"
  security_enabled = true
}

resource "azuread_group_member" "portalsAdmins" {
  count = length(data.azuread_group.portalsAdmins.members)
  group_object_id  = azuread_group.portalsAdmins.id
  member_object_id = data.azuread_group.portalsAdmins.members[count.index]
}

resource "azuread_group_member" "dbsAdmins" {
  count = length(data.azuread_group.portalsAdmins.members)
  group_object_id  = azuread_group.dbsAdmins.id
  member_object_id = data.azuread_group.dbsAdmins.members[count.index]
}
