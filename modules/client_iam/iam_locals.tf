locals {
  app_grps_map = {
    for app_grp in var.application_groups : "${app_grp.name}" => app_grp
  }

  apps_list = flatten([
    for app_grp in var.application_groups : [
      for app in app_grp.applications : {
        application_group_id = azurerm_virtual_desktop_application_group.avdag["${app_grp.name}"].id
        group_name           = app_grp.name
        app                  = app
      } if app.path != "" # checking if the path is empty and then if so, filters those out. 
    ]
  ])

  apps_map = {
    for obj in local.apps_list : "${obj.group_name}${obj.app.name}" => obj
  }

  # Little fancy dancing to massage the collection of users into a usable format
  csv_data = csvdecode(data.http.csv_data.body)

  importable_users = [
    for idx, row in local.csv_data : {
      key             = "${var.client_name}_${row.first_name}${row.last_name}_${substr(parseint(substr(upper(sha256(format("%s%s", row.email, var.client_name))), 0, 4), 16), 0, 4)}"
      base_data       = row
      user_name       = lower("${row.first_name}.${row.last_name}${substr(parseint(substr(upper(sha256(format("%s%s", row.email, var.client_name))), 0, 4), 16), 0, 4)}")
      password        = "Def@uLtP@$$wd${substr(parseint(substr(upper(sha256(format("%s%s", row.email, var.client_name))), 0, 4), 16), 0, 4)}!"
      account_enabled = lower(row.account_enabled)
    }
  ]

  users_map = {
    for user in local.importable_users : "${user.key}" => user
  }

  app_group_config = flatten([
    for app_grp in var.application_groups : {
            application_group    = app_grp.name
            application_group_id = azurerm_virtual_desktop_application_group.avdag[app_grp.name].id # applications.tf
            display_name     = app_grp.friendly_name
            members =  [for user in local.importable_users : azuread_user.client_users[user.key].id if lower(user.base_data["${app_grp.import_field_name}"]) == "x"]
        } if app_grp.import_field_name != ""
    ]
  )

  app_group_config_mapping = {
    for mapping in local.app_group_config : "${mapping.application_group}" => mapping
  }
}