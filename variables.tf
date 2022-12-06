#cn is short for computername. add "-citrix-01" replacing citrix with the service name
#br is short for backup region
locals {
  backup_region = lookup(var.backup_pair, var.primary_region)
  cn            = var.client_name
  vm_count      = local.test_enabled ? 1 : var.rdsh_count
  default_tags = {
    ManagedByTerraform = "True"
    Environment        = "${var.environment}"
    client             = "${var.client_name}"
    Customer           = "${var.client_name}"
    CreatedByOctopus   = "True"
    CreatedByTerraform = "True"
    logging            = "enabled"
    hostingenv         = var.hostingenv
    shared_name        = var.shared_name
    # LastUpdatedByTerraform = formatdate("M/D/YYYY hh:mm:ss AA", timestamp())  #commenting until I can look at the impact of this further
  }
  vm_tags = {
    alwayson = "true",
    monitor  = "true",
    region   = "${var.primary_region}",
  }
  app_tags = {
    alwayson = "true",
    # GuestConfigPolicyCertificateValidation = "true",
    monitor = "true",
    region  = "${var.primary_region}",
    role    = "app",
  }
  sql_web_tags = {
    automanage = "true"
  }
  sql_tags = {
    role = "sql"
  }
  web_tags = {
    role = "web"
  }
  test_users   = tonumber(var.test_users)
  sql_dsc_name = "${var.client_name}_SQLServer" # Creates a name for the SQL server DSC configuration
  test_enabled = tobool(var.test_enabled)
  env_vnet_id  = var.hostingenv != "shared_environment" ? 250 : 251
}

variable "subscription_id" {
  default = "#{azureaccountSubscriptionNumber}"
}

variable "avd_vm_size" {
  type        = string
  default     = "Standard_D4s_v4"
  description = "Size of Citrix connector servers"
}

# variable "ad_vm_size" {
#   type        = string
#   default     = "Standard_B2ms"
#   description = "Size of Active Directory servers"
# }

variable "sql_vm_size" {
  type        = string
  default     = "#{sql_vm_size}"
  description = "Size of SQL servers"
}

variable "web_vm_size" {
  type        = string
  default     = "Standard_B2ms"
  description = "Size of web servers"
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

variable "allowed_ip" {
  default     = "#{allowed_ip}"
  description = "ip of octoworkers to enable access to storage accounts"
  type        = string
}

variable "application_groups" {
  default = [
    {
      name              = "ssms"
      friendly_name     = "Microsoft SQL Server Management Studio 18"
      description       = "Microsoft SQL Server Management Studio 18"
      import_field_name = "sql_management_studio"
      applications = [{
        name           = "ssms"
        friendly_name  = "SQL Management Studio"
        description    = "SQL Management Studio"
        path           = "C:\\Program Files (x86)\\Microsoft SQL Server Management Studio 18\\Common7\\IDE\\Ssms.exe"
        icon_path      = "C:\\Program Files (x86)\\Microsoft SQL Server Management Studio 18\\Common7\\IDE\\Ssms.exe"
        show_in_portal = true
      }]
    },
    {
      name              = "msexcel"
      friendly_name     = "Excel 2016"
      description       = "Microsoft Excel 2016"
      import_field_name = "ms_excel"
      applications = [{
        name           = "msexcel"
        friendly_name  = "Excel"
        description    = "Microsoft Excel 2016"
        path           = "C:\\Program Files\\Microsoft Office\\Office16\\EXCEL.EXE"
        icon_path      = "C:\\Program Files\\Microsoft Office\\Office16\\EXCEL.EXE"
        show_in_portal = true
      }]
    },
    {
      name              = "msword"
      friendly_name     = "Word"
      description       = "Microsoft Word"
      import_field_name = "ms_word"
      applications = [{
        name           = "msword"
        friendly_name  = "Word"
        description    = "Microsoft Word"
        path           = "C:\\Program Files\\Microsoft Office\\Office16\\WINWORD.EXE"
        icon_path      = "C:\\Program Files\\Microsoft Office\\Office16\\WINWORD.EXE"
        show_in_portal = true
      }]
    },
    {
      name              = "base"
      friendly_name     = "Base"
      description       = "Company AVD Base App Groups"
      import_field_name = ""
      applications      = []
    }
  ]
  description = "Application groups"
  type = list(object({
    name              = string
    friendly_name     = string
    description       = string
    import_field_name = string
    applications = list(object({
      name           = string
      friendly_name  = string
      description    = string
      path           = string
      icon_path      = string
      show_in_portal = bool
    }))
  }))
}

variable "avd_users" {
  type        = list(string)
  description = "AVD users"
  default     = []
}

variable "azureaccountClientID" {
  default = "#{azureaccountClientID}"
}

variable "backup_pair" {
  type = map(any)

  default = {
    "eastus"           = "westus"
    "westus"           = "eastus"
    "northcentralus"   = "southcentralus"
    "southcentralus"   = "northcentralus"
  }
  description = "Location of backup datacenter."
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

variable "csv_file_path" {
  default     = "#{user_import_csv_file_uri}"
  description = "File URI to the client's avd-users-import.csv file."
  type        = string
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

variable "dsc_json_values_file" {
  type    = string
  default = "#{dsc_json_values_file}"
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

# Key Vault variables
variable "msix_code_sign_key_vault_resource_group_name" {
  type        = string
  default     = "avd-rg1"
  description = "(Required) The name of the Resource Group in which the key vault exists."
}

variable "msix_code_sign_key_vault_name" {
  default = "#{msix_code_sign_key_vault_name}"
  # default     = "jkquickdirty"
  description = "A key vault name which stores the certificate and provides the certificate url."
  type        = string
}

variable "msix_code_sign_key_vault_certificate_name" {
  default = "#{msix_code_sign_key_vault_certificate_name}"
  # default     = "CompanySelfCert"
  description = "The name of a Key Vault Certificate."
  type        = string
}

variable "msix_code_sign_key_vault_id" {
  default     = "#{msix_code_sign_key_vault_id}"
  description = "A key vault id which stores the certificate and provides the certificate url."
  type        = string
}

variable "msix_code_sign_key_vault_certificate_url" {
  default     = "#{msix_code_sign_key_vault_certificate_url}"
  description = "The Secret URL of a Key Vault Certificate."
  type        = string
}

variable "msix_code_sign_key_vault_certificate_store" {
  default     = "#{msix_code_sign_key_vault_certificate_store}"
  description = "The certificate store on the Virtual Machine where the certificate should be added."
  type        = string
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

variable "rand_id" {
  default     = "#{rand_id}"
  description = "Random ID assigned to the environment"
}

variable "rdsh_count" {
  default     = "#{rdsh_count}"
  description = "Number of AVD machines to deploy"
}

variable "smtp_key" {
  default   = "#{smtp_key}"
  sensitive = true
}

variable "soft_delete" {
  default     = false
  type        = bool
  description = "(optional) describe your variable"
}

variable "sql_connectivity_update_password" {
  default   = "#{sql_connectivity_update_password}"
  sensitive = true
}

variable "sql_connectivity_update_username" {
  default = "#{sql_connectivity_update_username}"
}

variable "test_enabled" {
  default     = true
  description = "Determines if this is a test env or not"
  type        = bool
}

variable "test_users" {
  default     = "#{test_users}"
  description = "This is where you would put the number of users you need for testing"
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

variable "mapped_vnet_regions" {
  type = map(any)
  default = {
    "East US"        = "aadds-primary-vnet"
    "East US 2"      = "aadds-primary-vnet"
    "West US"        = "aadds-replica-vnet"
    "northcentralus" = "aadds-primary-vnet"
    "southcentralus" = "aadds-replica-vnet"
    "Central US"     = "aadds-replica-vnet"
    "eastus"         = "aadds-primary-vnet"
    "westus"         = "aadds-replica-vnet"
  }
}

variable "mapped_vnet_rgs" {
  type = map(any)

  default = {
    "aadds-primary-vnet" = "aadds-primary-rg"
    "aadds-replica-vnet" = "aadds-replica-rg"
  }
}

variable "sql_count" {
  default = 1
}
variable "web_count" {
  default = 1
}

# Variables from modules
variable "storage_access_role" {
  default = false
}

variable "hostingenv" {
  default     = "#{hostingenv}"
  description = "the type of env for terraform to build. Dedicated envs build infrastructure and iam, base envs only build infrastructure, shared envs only use existing infrastructure to deploy their iam to."
}
variable "shared_name" {
  default     = "#{shared_name}"
  description = "Tag for identifying appropriate resources."
}
variable "token" {
  default = "#{token}"
}
locals {
  #local values for builder logic
  iam_enabled  = var.hostingenv != "base_environment" ? true : false
  sql_enabled  = var.hostingenv != "shared_environment" ? true : false
  web_enabled  = var.hostingenv != "shared_environment" ? true : false
  host_enabled = var.hostingenv != "shared_environment" ? true : false
}
