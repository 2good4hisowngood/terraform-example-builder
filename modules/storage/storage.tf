locals {
  fileshares = [azurerm_storage_share.msix, azurerm_storage_share.FSShare, azurerm_storage_share.reports]
  test_enabled_client_accounts = [azurerm_storage_account.storage, azurerm_storage_account.scripts]
}


# generate a random string (consisting of four characters)
# https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string
resource "random_string" "random" {
  length  = 4
  upper   = false
  special = false
}

## Azure Storage Accounts requires a globally unique names
## https://docs.microsoft.com/en-us/azure/storage/common/storage-account-overview
## Create a File Storage Account 
#tfsec:ignore:azure-storage-queue-services-logging-enabled
resource "azurerm_storage_account" "storage" {
  name                = "${var.client_name}filestorage${random_string.random.id}"
  resource_group_name = var.rg1.name
  location            = var.primary_region

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  access_tier               = "Hot"
  allow_blob_public_access  = true
  min_tls_version          = "TLS1_2"

  azure_files_authentication {
    directory_type = "AADDS"
  }

  tags = merge(local.default_tags, { type = "storage" })
}

################################
#
# MSIX storage
#
###############################

resource "azurerm_storage_share" "msix" {
  name                 = "msix"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = "1024"
}

################################
#
# FSLogix storage
#
###############################

resource "azurerm_storage_share" "FSShare" {
  name                 = "fslogix"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = "1024"
}

################################
#
# Script storage
#
###############################

#tfsec:ignore:azure-storage-queue-services-logging-enabled
resource "azurerm_storage_account" "scripts" {
  name                = "${var.client_name}scripts${random_string.random.id}"
  resource_group_name = var.rg1.name
  location            = var.primary_region

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  access_tier               = "Hot"
  allow_blob_public_access  = true
  min_tls_version          = "TLS1_2"

  depends_on = [
    azurerm_storage_account.storage
  ]

  tags = merge(local.default_tags, { type = "storage" })
}

resource "time_offset" "six_months" {
  offset_months = 6
}

data "azurerm_storage_account_sas" "scripts" {
  connection_string = azurerm_storage_account.scripts.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = true
    container = true
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = "2018-03-21T00:00:00Z"
  expiry = time_offset.six_months.id

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = true
    create  = true
    update  = true
    process = true
  }
}


resource "azurerm_storage_container" "scripts" {
  name                  = "scripts"
  storage_account_name  = azurerm_storage_account.scripts.name
  container_access_type = "private"
  depends_on = [
    var.storage_access_role
  ]
}

# Permissions must be assigned to the storage account for the SP to access the contents, subscription level permissions are insufficient.
# Permissions need time to propogate from the storage account in the var.storage_access_role resource.
# This sleep resource will sit between the containers and their blobs to give a short timer to ensure permissions propogate.
resource "time_sleep" "container_rbac" {
  create_duration = "5m"

  triggers = {
    scope = var.storage_access_role.scope
    name  = azurerm_storage_container.scripts.name
    setup_host_content = data.template_file.setup_host.rendered
    setup_sql_content = data.template_file.setup-sql.rendered
  }

  depends_on = [
    azurerm_storage_account.scripts,
    azurerm_storage_account.storage,
    var.storage_access_role
  ]
}
# time_sleep.container_rbac.triggers["azurerm_storage_container.scripts.name"]

# Scripts and templatefiles

data "template_file" "setup_host" {
  template = file("${path.module}//scripts//setup-host.tpl")

  vars = {
    storageAccountName = azurerm_storage_account.storage.name
    storageAccountKey  = azurerm_storage_account.storage.primary_access_key
    domain             = var.domain
    aad_group_name     = var.aad_group_name
  }
}

resource "azurerm_storage_blob" "setup_host" {
  name                   = "setup-host.ps1"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = time_sleep.container_rbac.triggers["name"]
  type                   = "Block"
  source_content         = time_sleep.container_rbac.triggers["setup_host_content"] #"${path.module}//scripts//setup-host.ps1"
  depends_on = [
    var.storage_access_role,
    data.template_file.setup_host,
    time_sleep.container_rbac
  ]
}

data "template_file" "setup-sql" {
  template = file("${path.module}//scripts//setup-sql.tpl")

  vars = {
    client_name = var.client_name
  }
}

resource "azurerm_storage_blob" "setup-sql" {
  name                   = "setup-sql.ps1"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = time_sleep.container_rbac.triggers["name"]
  type                   = "Block"
  source_content         = time_sleep.container_rbac.triggers["setup_sql_content"] # "${path.module}//scripts//setup-sql.ps1"
  depends_on = [
    var.storage_access_role,
    data.template_file.setup-sql,
    time_sleep.container_rbac
  ]
}

data "template_file" "setup-web" {
  template = file("${path.module}//scripts//setup-web.tpl")

  vars = {
    # storageAccountName    = azurerm_storage_account.storage.name
    # storageAccountKey = azurerm_storage_account.storage.primary_access_key
    # domain         = var.domain
    # aad_group_name          = var.aad_group_name
  }
}

resource "azurerm_storage_blob" "setup-web" {
  name                   = "setup-web.ps1"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = time_sleep.container_rbac.triggers["name"]
  type                   = "Block"
  source_content         = data.template_file.setup-web.rendered #"${path.module}//scripts//setup-web.ps1"
  depends_on = [
    var.storage_access_role,
    data.template_file.setup-web,
    time_sleep.container_rbac
  ]
}

################################
#
# DSC storage
#
###############################

data "template_file" "dsc-sql" {
  template = file("${path.module}//scripts//sqlserverdsc.ps1")

  vars = {
    ApiKey           = var.octopus_api_key
    dsc_name         = local.sql_dsc_name
    OctopusServerUrl = var.octopus_server_url
    Environments     = var.octopus_environment
    Space            = var.octopus_space
  }
}

resource "azurerm_storage_blob" "dsc-sql" {
  name                   = "sqlserverdsc.ps1"
  storage_account_name   = azurerm_storage_account.scripts.name
  storage_container_name = time_sleep.container_rbac.triggers["name"]
  type                   = "Block"
  source_content         = data.template_file.dsc-sql.rendered # "${path.module}//scripts//setup-sql.ps1"
  depends_on = [
    var.storage_access_role,
    data.template_file.dsc-sql,
    time_sleep.container_rbac
  ]
}