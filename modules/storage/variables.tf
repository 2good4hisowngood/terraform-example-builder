locals {
    default_tags = {
    ManagedByTerraform = "True"
    Environment        = "${var.environment}"
    client             = "${var.client_name}"
    Customer           = "${var.client_name}"
    CreatedByOctopus   = "True"
    CreatedByTerraform = "True"
    logging            = "enabled"
    # LastUpdatedByTerraform = formatdate("M/D/YYYY hh:mm:ss AA", timestamp())  #commenting until I can look at the impact of this further
  }
  sql_dsc_name = "${var.client_name}_SQLServer" # Creates a name for the SQL server DSC configuration
}
variable "client_name" {
  type        = string
  default     = "#{client_name}"
  description = "Name of client. May be XXHDA where XX is replaced with abreviated client initials."

  validation {
    condition     = length(var.client_name) <= 5
    error_message = "The name of the client exceeds the maximum allowable length of '5'."
  }
}

variable "primary_region" {
  type        = string
  default     = "#{primary_region}"
  description = "Location of primary datacenter. Should look like: 'US Gov Virginia', 'US Gov Texas', 'US Gov Arizona'"
}

variable "storage_access_role" {
  default = false
}

variable "rg1" { 
}
variable "domain" {
  default     = "#{domain}"
  description = "The environment's domain name without the suffix"
  type        = string
}
variable "environment" {
  type        = string
  description = "Environment denoted in Octopus"
  default     = "#{environment}"
}
variable "aad_group_name" {
  type        = string
  default     = "#{aad_group_name}"
  description = "Azure Active Directory Group for AVD users"
}
variable "octopus_api_key" {
  default = "#{AVDOctopusRegistrationAPIKey}"
}

variable "octopus_server_url" {
  default = "#{Octopus.Web.BaseUrl}"
}

variable "octopus_environment" {
  default = "#{Octopus.Environment.Name}"
}

variable "octopus_space" {
  default = "#{Octopus.Space.Name}"
}