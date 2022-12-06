resource "azurerm_virtual_desktop_application_group" "avdag" {
  for_each            = local.app_grps_map
  name                = "${var.client_name}-${each.key}-ag"
  location            = var.primary_region
  resource_group_name = var.rg1.name
  type                = "RemoteApp"
  host_pool_id        = var.azurerm_virtual_desktop_host_pool
  friendly_name       = each.value.friendly_name
  description         = each.value.description
  tags                = var.default_tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "avdag_assoc" {
  for_each             = azurerm_virtual_desktop_application_group.avdag
  workspace_id         = var.azurerm_virtual_desktop_workspace
  application_group_id = each.value.id
}

resource "azurerm_virtual_desktop_application" "avdag_apps" {
  for_each                     = local.apps_map
  name                         = each.value.app.name
  application_group_id         = each.value.application_group_id
  friendly_name                = each.value.app.friendly_name
  description                  = each.value.app.description
  path                         = each.value.app.path
  show_in_portal               = each.value.app.show_in_portal
  icon_path                    = each.value.app.icon_path
  icon_index                   = 0
  command_line_argument_policy = "DoNotAllow"
  command_line_arguments       = "--incognito"

  depends_on = [
    # Using an explicity depends on instead of relying on an implicit depends on hoppping
    # through the local apps_map variable, through the for_each, to the reference to the
    # app groups to ensure ordering.
    azurerm_virtual_desktop_application_group.avdag,
  ]
}