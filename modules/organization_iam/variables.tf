variable "aad_group_name" {
  default = "#{aad_group_name}"
}

variable "application_groups" {
  default = "#{application_groups}"
}

variable "azureaccountClientID" {
  default = "#{azureaccountClientID}"
}

variable "client_name" {
  default = "#{client_name}"
}

variable "csv_file_path" {
  default = "#{csv_file_path}"
}

variable "domain_name" {
  default = "#{domain_name}"
}

variable "primary_region" {
  default = "#{primary_region}"
}






# Import from other modules, set in main.tf

variable "azurerm_virtual_desktop_host_pool" {
  default = ""
}
variable "azurerm_virtual_desktop_workspace" {
  default = ""
}
variable "default_tags" {
  default = ""
}
variable "scripts_account_id" {
  default = ""
}
variable "storage_account_id" {
  default = ""
}
variable "rg1" {
}

