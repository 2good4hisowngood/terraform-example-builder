data "azurerm_log_analytics_workspace" "avd_logs" {
  name                = lower("avdlog${var.environment}")
  resource_group_name = "avd-rg1"
}

resource "time_rotating" "avd_token" {
  rotation_days = 30
}

resource "azurerm_virtual_desktop_workspace" "primary" {
  name                = "${var.client_name}-workspace"
  location            = var.rg1.location
  resource_group_name = var.rg1.name

  friendly_name = "${upper(var.client_name)}'s App Workspace"
  description   = "Company Hosted App"

  tags = merge(local.default_tags, { type = "workspaces" })
}

resource "azurerm_virtual_desktop_host_pool" "pooledbreadthfirst" {
  location            = var.primary_region
  resource_group_name = var.rg1.name
  # personal_desktop_assignment_type = "Automatic"
  name                     = "${var.client_name}-avdhp"
  friendly_name            = "pooledbreadthfirst"
  validate_environment     = false
  start_vm_on_connect      = false
  custom_rdp_properties    = "audiocapturemode:i:0;audiomode:i:2;drivestoredirect:s:*;encode redirected video capture:i:0;camerastoredirect:s:;devicestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:0;redirectlocation:i:0;redirectprinters:i:1;redirectsmartcards:i:0;usbdevicestoredirect:s:"
  description              = "Acceptance Test: A pooled host pool - pooledbreadthfirst"
  type                     = "Pooled"
  maximum_sessions_allowed = 16
  load_balancer_type       = "BreadthFirst"

  # registration_info {
  #   expiration_date = time_rotating.avd_token.rotation_rfc3339
  # }

  lifecycle {
    ignore_changes = [
      load_balancer_type
    ]
  }

  tags = merge(local.default_tags, { type = "hostpool" })
}

resource "azurerm_virtual_desktop_host_pool_registration_info" "pooledbreadthfirst" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.pooledbreadthfirst.id
  expiration_date = time_rotating.avd_token.rotation_rfc3339

  depends_on = [
    azurerm_virtual_desktop_host_pool.pooledbreadthfirst
  ]
}

module "dr_avd_host" {
  # This is for the DR Hosts
  # They can be in the same host pool, but will need things changed like the region  
  source = "./dr_avd_host"
  count = var.host_enabled ? 1 : 0

  aad_group_name       = var.aad_group_name
  admin_password       = var.admin_password
  admin_username       = var.admin_username
  client_name          = var.client_name
  client_number        = var.client_number
  domain_name          = var.domain_name
  domain_user_upn      = var.domain_user_upn
  environment          = var.environment
  image_gallery_name   = var.image_gallery_name
  ou_path              = var.ou_path
  primary_region       = local.backup_region
  rdsh_count           = local.vm_count
  timezone             = var.timezone
  vnet_peerings        = var.vnet_peerings

  avd_vm_size  = var.avd_vm_size

  hostpool = azurerm_virtual_desktop_host_pool.pooledbreadthfirst
  hostpool_registration_token = azurerm_virtual_desktop_host_pool_registration_info.pooledbreadthfirst.token
  resource_group = var.rg2
  setup_host_template = var.setup_host_template
  setup_host_blob = var.setup_host_blob
  storage_account_name = var.storage_account.name
  storage_account_key = var.storage_account.primary_access_key
  scripts_account_name = var.scripts_account.name
  scripts_account_key = var.scripts_account.primary_access_key
  subnet = azurerm_subnet.app2
  xmlCfg = "${path.module}/scripts/wadcfgxml.tmpl"

  depends_on = [
    var.setup_host_blob,
    
    azurerm_subnet_network_security_group_association.app1,
    azurerm_virtual_network_peering.out-primary,
    azurerm_virtual_network_peering.in-primary,
    azurerm_virtual_network_peering.in-secondary
  ]
}




module "avd_host" {
  # This is for the DR Hosts
  # They can be in the same host pool, but will need things changed like the region  
  source = "./avd_host"
  count = var.host_enabled ? 1 : 0

  aad_group_name       = var.aad_group_name
  admin_password       = var.admin_password
  admin_username       = var.admin_username
  client_name          = var.client_name
  client_number        = var.client_number
  domain_name          = var.domain_name
  domain_user_upn      = var.domain_user_upn
  environment          = var.environment
  image_gallery_name   = var.image_gallery_name
  ou_path              = var.ou_path
  primary_region       = var.primary_region
  rdsh_count           = local.vm_count
  timezone             = var.timezone
  vnet_peerings        = var.vnet_peerings

  avd_vm_size  = var.avd_vm_size

  hostpool = azurerm_virtual_desktop_host_pool.pooledbreadthfirst
  hostpool_registration_token = azurerm_virtual_desktop_host_pool_registration_info.pooledbreadthfirst.token
  resource_group = var.rg1
  setup_host_template = var.setup_host_template
  setup_host_blob = var.setup_host_blob
  storage_account_name = var.storage_account.name
  storage_account_key = var.storage_account.primary_access_key
  scripts_account_name = var.scripts_account.name
  scripts_account_key = var.scripts_account.primary_access_key
  subnet = azurerm_subnet.app1
  xmlCfg = "${path.module}/scripts/wadcfgxml.tmpl"

  depends_on = [
    var.setup_host_blob,
    
    azurerm_subnet_network_security_group_association.app1,
    azurerm_virtual_network_peering.out-primary,
    azurerm_virtual_network_peering.in-primary,
    azurerm_virtual_network_peering.in-secondary
  ]
}

