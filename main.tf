# Resource Group for Primary Datacenter

resource "azurerm_resource_group" "rg1" {
  name     = "${var.client_name}-prod-rg1"
  location = var.primary_region
  tags     = local.default_tags
}

# Resource Group for Disaster Recovery Datacenter

resource "azurerm_resource_group" "rg2" {
  name     = "${var.client_name}-bckp-rg2"
  location = local.backup_region
  tags     = local.default_tags
}

data "azurerm_resources" "vnets" {
  type = "Microsoft.Network/virtualNetworks"

  required_tags = {
    role = "azops"
  }
}

# Bastion Host Peering
data "azurerm_resources" "bastionvnet" {
  type = "Microsoft.Network/virtualNetworks"
  required_tags = {
    role = "bastion"
  }
}


module "avd" {
  source = "./modules/avd"

  aad_group_name                   = var.aad_group_name
  admin_password                   = var.admin_password
  admin_username                   = var.admin_username
  allowed_ip                       = var.allowed_ip
  avd_users                        = var.avd_users
  azureaccountClientID             = var.azureaccountClientID
  client_name                      = var.client_name
  client_number                    = var.client_number
  csv_file_path                    = var.csv_file_path
  domain_name                      = var.domain_name
  domain_user_upn                  = var.domain_user_upn
  environment                      = var.environment
  image_gallery_name               = var.image_gallery_name
  octopus_api_key                  = var.octopus_api_key
  octopus_server_url               = var.octopus_server_url
  octopus_environment              = var.octopus_environment
  octopus_space                    = var.octopus_space
  ou_path                          = var.ou_path
  primary_region                   = var.primary_region
  rand_id                          = var.rand_id
  rdsh_count                       = var.rdsh_count
  sql_connectivity_update_password = var.sql_connectivity_update_password
  sql_connectivity_update_username = var.sql_connectivity_update_username
  smtp_key                         = var.smtp_key

  soft_delete   = var.soft_delete
  test_enabled  = local.test_enabled
  test_users    = var.test_users
  timezone      = var.timezone
  vnet_peerings = var.vnet_peerings
  host_enabled  = local.host_enabled

  avd_vm_size         = var.avd_vm_size
  web_vm_size         = var.web_vm_size
  sql_vm_size         = var.sql_vm_size
  rg1                 = azurerm_resource_group.rg1
  rg2                 = azurerm_resource_group.rg2
  import_aadds_vnets  = data.azurerm_resources.vnets
  import_bastion_vnet = data.azurerm_resources.bastionvnet

  random_id       = module.storage.random_id
  fileshares      = module.storage.fileshares
  scripts_account = module.storage.scripts_account
  storage_account = module.storage.storage_account
  setup_host_blob = module.storage.setup_host_blob

  setup_host_template = data.template_file.setup_host.rendered

  subscription_id              = var.subscription_id
  shared_name                  = var.shared_name
  env_vnet_id                  = local.env_vnet_id
  test_enabled_client_accounts = module.storage.test_enabled_client_accounts

  # From IAM module
  storage_access_role = module.ecs.storage_access_role
  depends_on = [
    azurerm_resource_group.rg1,
    azurerm_resource_group.rg2,
    module.storage
  ]
}
locals {
  # azurerm_virtual_desktop_workspace = 
}

module "ecs" {

  source = "./modules/organization_iam"

  aad_group_name       = var.aad_group_name
  application_groups   = var.application_groups
  azureaccountClientID = var.azureaccountClientID
  client_name          = var.client_name
  csv_file_path        = var.csv_file_path
  domain_name          = var.domain_name
  primary_region       = var.primary_region

  # values in from other modules
  default_tags                      = local.default_tags
  scripts_account_id                = module.storage.scripts_account.id
  storage_account_id                = module.storage.storage_account.id
  azurerm_virtual_desktop_host_pool = module.avd.azurerm_virtual_desktop_host_pool
  azurerm_virtual_desktop_workspace = module.avd.azurerm_virtual_desktop_workspace

  rg1 = azurerm_resource_group.rg1
}



module "iam" {
  source = "./modules/client_iam"
  count  = local.iam_enabled ? 1 : 0

  aad_group_name       = var.aad_group_name
  application_groups   = var.application_groups
  azureaccountClientID = var.azureaccountClientID
  client_name          = var.client_name
  csv_file_path        = var.csv_file_path
  domain_name          = var.domain_name
  primary_region       = var.primary_region
  hostingenv           = var.hostingenv
  shared_name          = var.shared_name

  # values in from other modules
  default_tags                      = local.default_tags
  scripts_account_id                = module.storage.scripts_account.id
  storage_account_id                = module.storage.storage_account.id
  azurerm_virtual_desktop_host_pool = module.avd.azurerm_virtual_desktop_host_pool
  azurerm_virtual_desktop_workspace = module.avd.azurerm_virtual_desktop_workspace

  rg1 = azurerm_resource_group.rg1
}
# "/subscriptions/#{subscription_id}/resourceGroups/${var.shared_name}-prod-rg1/providers/Microsoft.DesktopVirtualization/hostpools/${var.shared_name}-avdhp" # module.avd.azurerm_virtual_desktop_host_pool

module "sql" {
  source = "./modules/sql"
  count  = local.sql_enabled ? 1 : 0

  admin_password                   = var.admin_password
  admin_username                   = var.admin_username
  client_name                      = var.client_name
  client_number                    = var.client_number
  domain_name                      = var.domain_name
  domain_user_upn                  = var.domain_user_upn
  ou_path                          = var.ou_path
  sql_connectivity_update_password = var.sql_connectivity_update_password
  sql_connectivity_update_username = var.sql_connectivity_update_username
  sql_count                        = var.sql_count

  # values in from other modules
  default_tags    = local.default_tags
  scripts_account = module.storage.scripts_account
  rg1             = module.avd.rg1
  rg2             = module.avd.rg2
  rv1             = module.avd.rv1
  rv2             = module.avd.rv2
  vnet1           = module.avd.vnet1
  vnet2           = module.avd.vnet2
  sql_vm_size     = var.sql_vm_size
  timezone        = var.timezone
  vm_tags         = local.vm_tags
  sql_web_tags    = local.sql_web_tags
  test_enabled    = var.test_enabled
  smtp_key        = var.smtp_key
  peering_out     = module.avd.peering_out
  peering_in      = module.avd.peering_in
  # setup-sql                    = module.avd.setup-sql
  bp1                          = module.avd.bp1
  site_replication_policy      = module.avd.site_replication_policy
  recovery_container_primary   = module.avd.recovery_container_primary
  fabric_primary               = module.avd.fabric_primary
  fabric_secondary             = module.avd.fabric_secondary
  recovery_container_secondary = module.avd.recovery_container_secondary
  recovery_storage_cache       = module.avd.recovery_storage_cache
  sql_tags                     = local.sql_tags

  depends_on = [
    module.avd
  ]
}


module "web" {
  source = "./modules/web"
  count  = local.web_enabled ? 1 : 0

  admin_password  = var.admin_password
  admin_username  = var.admin_username
  client_name     = var.client_name
  client_number   = var.client_number
  domain_name     = var.domain_name
  domain_user_upn = var.domain_user_upn
  ou_path         = var.ou_path
  web_count       = var.web_count

  # values in from other modules
  default_tags    = local.default_tags
  scripts_account = module.storage.scripts_account
  rg1             = module.avd.rg1
  rg2             = module.avd.rg2
  rv1             = module.avd.rv1
  rv2             = module.avd.rv2
  vnet1           = module.avd.vnet1
  vnet2           = module.avd.vnet2
  web_vm_size     = var.web_vm_size
  timezone        = var.timezone
  vm_tags         = local.vm_tags
  sql_web_tags    = local.sql_web_tags
  test_enabled    = var.test_enabled
  peering_out     = module.avd.peering_out
  peering_in      = module.avd.peering_in
  # setup-web                   = module.avd.setup-web
  bp1                          = module.avd.bp1
  site_replication_policy      = module.avd.site_replication_policy
  recovery_container_primary   = module.avd.recovery_container_primary
  fabric_primary               = module.avd.fabric_primary
  fabric_secondary             = module.avd.fabric_secondary
  recovery_container_secondary = module.avd.recovery_container_secondary
  recovery_storage_cache       = module.avd.recovery_storage_cache
  web_tags                     = local.web_tags

  depends_on = [
    module.avd
  ]
}

module "storage" {
  source = "./modules/storage"

  client_name         = var.client_name
  primary_region      = var.primary_region
  storage_access_role = module.ecs.storage_access_role
  rg1                 = azurerm_resource_group.rg1
  domain              = var.domain
  aad_group_name      = var.aad_group_name
  octopus_api_key     = var.octopus_api_key
  octopus_server_url  = var.octopus_server_url
  octopus_environment = var.octopus_environment
  octopus_space       = var.octopus_space
  environment         = var.environment
}