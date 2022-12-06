
data "azuread_service_principal" "main_avd" {
  display_name = "Windows Virtual Desktop"
}
###################################
#
# Primary Scoped rbac
#
###################################
resource "random_uuid" "main" {
} # This provides the random name later
resource "azurerm_role_definition" "client_avd_main" {
  name        = "${var.client_name}-AVD-AutoScale-rg1"
  scope       = var.rg1.id
  description = "AVD AutoScale Role"
  permissions {
    actions = [
      "Microsoft.Insights/eventtypes/values/read",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.DesktopVirtualization/hostpools/read",
      "Microsoft.DesktopVirtualization/hostpools/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read"
    ]
    not_actions = []
  }
  assignable_scopes = [
    var.rg1.id,
  ]
}

resource "azurerm_role_assignment" "client_avd_main" {
  name                             = random_uuid.main.result
  scope                            = var.rg1.id
  role_definition_id               = azurerm_role_definition.client_avd_main.role_definition_resource_id
  principal_id                     = data.azuread_service_principal.main_avd.id
  skip_service_principal_aad_check = true
}
###################################
#
# DR Scoped rbac
#
###################################
resource "random_uuid" "dr" {
} # This provides the random name later
resource "azurerm_role_definition" "client_avd_dr" {
  name        = "${var.client_name}-DR-AVD-AutoScale-rg2"
  scope       = var.rg2.id
  description = "AVD AutoScale Role"
  permissions {
    actions = [
      "Microsoft.Insights/eventtypes/values/read",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/powerOff/action",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.DesktopVirtualization/hostpools/read",
      "Microsoft.DesktopVirtualization/hostpools/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/write",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/delete",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/sendMessage/action",
      "Microsoft.DesktopVirtualization/hostpools/sessionhosts/usersessions/read"
    ]
    not_actions = []
  }
  assignable_scopes = [
    var.rg2.id,
  ]
}

resource "azurerm_role_assignment" "client_avd_dr" {
  name                             = random_uuid.dr.result
  scope                            = var.rg2.id
  role_definition_id               = azurerm_role_definition.client_avd_dr.role_definition_resource_id
  principal_id                     = data.azuread_service_principal.main_avd.id
  skip_service_principal_aad_check = true
}


###################################
#
# Scaling Plans
#
###################################

resource "azurerm_virtual_desktop_scaling_plan" "weekdays" {
  count = var.host_enabled ? 1 : 0
  name                = "${var.client_name}-scaling-plan"
  location            = var.rg1.location
  resource_group_name = var.rg1.name
  friendly_name       = "Scaling Plan Example"
  description         = "Standard Scaling Plan"
  exclusion_tag = "disaster_recovery"
  time_zone           = var.timezone
  schedule {
    name                                 = "Weekdays"
    days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    ramp_up_start_time                   = "07:00"
    ramp_up_load_balancing_algorithm     = "BreadthFirst"
    ramp_up_minimum_hosts_percent        = 33
    ramp_up_capacity_threshold_percent   = 15
    peak_start_time                      = "08:30"
    peak_load_balancing_algorithm        = "BreadthFirst"
    ramp_down_start_time                 = "19:00"
    ramp_down_load_balancing_algorithm   = "DepthFirst"
    ramp_down_minimum_hosts_percent      = 5
    ramp_down_force_logoff_users         = true
    ramp_down_wait_time_minutes          = 30
    ramp_down_notification_message       = "Good Evening, after-hours server shutdowns are in effect. Please save your work and log off in the next 30 minutes to prevent losing your work. Once your session has been disconnected automatically or 30 minutes have passed you can sign back in to resume working."
    ramp_down_capacity_threshold_percent = 5
    ramp_down_stop_hosts_when            = "ZeroSessions"
    off_peak_start_time                  = "22:00"
    off_peak_load_balancing_algorithm    = "DepthFirst"
  }
  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.pooledbreadthfirst.id
    scaling_plan_enabled = true
  }

  depends_on = [
    azurerm_virtual_desktop_host_pool.pooledbreadthfirst,
    azurerm_role_assignment.client_avd_dr,
    azurerm_role_assignment.client_avd_main
  ]
}


# # Only one scaling plan can be active per Host Pool
# resource "azurerm_virtual_desktop_scaling_plan" "weekends" {
#   name                = "Weekend-scaling-plan"
#   location            = var.rg1.location
#   resource_group_name = var.rg1.name
#   friendly_name       = "Weekend Scaling Plan Example"
#   description         = "Weekend Standard Scaling Plan"
#   time_zone           = var.timezone
#   schedule {
#     name                                 = "Weekend"
#     days_of_week                         = ["Saturday","Sunday"]
#     ramp_up_start_time                   = "07:00"
#     ramp_up_load_balancing_algorithm     = "BreadthFirst"
#     ramp_up_minimum_hosts_percent        = 15
#     ramp_up_capacity_threshold_percent   = 7
#     peak_start_time                      = "08:30"
#     peak_load_balancing_algorithm        = "BreadthFirst"
#     ramp_down_start_time                 = "19:00"
#     ramp_down_load_balancing_algorithm   = "DepthFirst"
#     ramp_down_minimum_hosts_percent      = 5
#     ramp_down_force_logoff_users         = true
#     ramp_down_wait_time_minutes          = 30
#     ramp_down_notification_message       = "Good Evening, after-hours server shutdowns are in effect. Please save your work and log off in the next 30 minutes to prevent losing your work. Once your session has been disconnected automatically or 30 minutes have passed you can sign back in to resume working."
#     ramp_down_capacity_threshold_percent = 5
#     ramp_down_stop_hosts_when            = "ZeroSessions"
#     off_peak_start_time                  = "22:00"
#     off_peak_load_balancing_algorithm    = "DepthFirst"
#   }
#   host_pool {
#     hostpool_id          = azurerm_virtual_desktop_host_pool.pooledbreadthfirst.id
#     scaling_plan_enabled = true
#   }

#   depends_on = [
#     azurerm_virtual_desktop_host_pool.pooledbreadthfirst,
#     azurerm_role_assignment.client_avd_dr,
#     azurerm_role_assignment.client_avd_main
#   ]
# }
