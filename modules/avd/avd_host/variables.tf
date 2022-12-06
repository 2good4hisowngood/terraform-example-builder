locals {
  cn            = var.client_name
  default_tags = {
    ManagedByTerraform = "True"
    Environment        = "${var.environment}"
    client             = "${var.client_name}"
    Customer           = "${var.client_name}"
    CreatedByOctopus   = "True"
    CreatedByTerraform = "True"
    logging            = "enabled"
  }
  vm_tags = {
    alwayson = "true",
    monitor  = "true",
    region   = "${var.primary_region}",
  }
  app_tags = {
    alwayson = "true",
    monitor  = "true",
    region   = "${var.primary_region}",
  }
  sql_web_tags = {
    automanage = "true"
  }
}

variable "avd_vm_size" {
  type        = string
  default     = "Standard_D4s_v4"
  description = "Size of Citrix connector servers"
}

variable "aad_group_name" {
  type        = string
  default     = "#{aad_group_name}"
  description = "Azure Active Directory Group for AVD users"
}

variable "admin_password" {
  type        = string
  default     = "#{admin_password}"
  description = "Default admin password"
  sensitive   = true
}

variable "admin_username" {
  type        = string
  default     = "#{admin_username}"
  description = "Default admin username"
}

variable "backup_pair" {
  type = map(any)

  default = {
    "Central US"       = "East US"
    "East US"          = "West US"
    "East US 2"        = "Central US"
    "North Central US" = "South Central US"
    "South Central US" = "North Central US"
    "West US"          = "East US"
    "US Gov Virginia"  = "US Gov Texas"
    "US Gov Texas"     = "US Gov Arizona"
    "US Gov Arizona"   = "US Gov Texas"
    "eastus"           = "westus"
    "westus"           = "eastus"
  }

  description = "Location of backup datacenter. Should look like: 'North Central US'"
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

variable "client_number" {
  type        = string
  default     = "#{client_number}"
  description = "number of client, to be used to create networking configurations"
}

variable "domain" {
  default     = "#{domain}"
  description = "The environment's domain name without the suffix"
  type        = string
}

variable "domain_name" {
  default     = "#{domain_name}"
  type        = string
  description = "Name of the domain to join"
}

variable "domain_user_upn" {
  type        = string
  default     = "#{domain_user_upn}"
  description = "Username for domain join (do not include domain name as this is appended)"
}

# app Master Image variables
variable "app_image_name" {
  type        = string
  default     = "app_template"
  description = "(Required) The name of the Custom Image to provision this Virtual Machine from."
}
# app Master Image variables
variable "app_image_resource_group_name" {
  type        = string
  default     = "avd-rg1"
  description = "(Required) The name of the Resource Group in which the Custom Image exists."
}
variable "image_gallery_name" {
  default     = "#{image_gallery_name}"
  description = "name of image gallery for env"
  type        = string
}

variable "environment" {
  type        = string
  description = "Environment denoted in Octopus"
  default     = "#{environment}"
}

variable "ou_path" {
  default     = "#{ou_path}"
  type        = string
  description = "path in AD for resources to be stored"
}

variable "primary_region" {
  type        = string
  default     = "#{primary_region}"
  description = "Location of primary datacenter. Should look like: 'US Gov Virginia', 'US Gov Texas', 'US Gov Arizona'"
}

variable "rdsh_count" {
  default     = "#{rdsh_count}"
  description = "Number of AVD machines to deploy"
}

variable "timezone" {
  type        = string
  default     = "#{timezone}"
  description = "Preferred timezone of client."
}

variable "vnet_peerings" {
  type = list(object({
    vnet_resource_group_name = string
    vnet_name                = string
  }))
  description = "List of remote virtual networks to peer with"
  default = [{
    vnet_name                = "aadds-primary-vnet"
    vnet_resource_group_name = "aadds-primary-rg"
    },
    {
      vnet_name                = "aadds-replica-vnet"
      vnet_resource_group_name = "aadds-replica-rg"
    }
  ]
}


variable "hostpool" {}
variable "hostpool_registration_token" {}
variable "resource_group" {}
variable "setup_host_template" {}
variable "setup_host_blob" {}
variable "storage_account_name" {}
variable "storage_account_key" {}
variable "scripts_account_name" {}
variable "scripts_account_key" {}
variable "subnet" {}
variable "xmlCfg" {}
