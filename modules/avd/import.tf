data "azurerm_automation_account" "main" {
  name                = "avd-automation-1"
  resource_group_name = "avd-rg1"
}

data "azurerm_storage_account" "setups" {
  name                = "appsetupfiles${var.rand_id}"
  resource_group_name = "avd-rg1"
}

resource "time_offset" "yesterday" {
  offset_days = -1
}

resource "time_offset" "tomorrow" {
  offset_months = 6
}

data "azurerm_storage_account_sas" "setups" {
  connection_string = data.azurerm_storage_account.setups.primary_connection_string
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
    file  = true
  }

  start  = time_offset.yesterday.rfc3339
  expiry = time_offset.tomorrow.rfc3339

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
  }
}