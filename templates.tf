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
data "template_file" "setup-web" {
  template = file("${path.module}//scripts//setup-web.tpl")

  vars = {
  }
}
data "template_file" "setup-sql" {
  template = file("${path.module}//scripts//setup-sql.tpl")

  vars = {
    client_name = var.client_name
  }
}
data "template_file" "setup_host" {
  template = file("${path.module}//scripts//setup-host.tpl")

  vars = {
    storageAccountName = module.storage.storage_account.name
    storageAccountKey  = module.storage.storage_account.primary_access_key
    domain             = var.domain
    aad_group_name     = var.aad_group_name
  }
}