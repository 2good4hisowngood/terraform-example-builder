terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.94.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.16.0"
    }
  }
  backend "remote" {
    organization = "company"
    workspaces {
      name = "test-DevOps-workspace" #"#{Octopus.Deployment.Tenant.Name}-#{Octopus.Environment.Name}-workspace"
    }
  }
}

provider "tfe" {
  token = var.token
}

provider "azuread" {
  # Configuration options
  client_id     = "#{azureaccountClientID}"
  client_secret = "#{azureaccountClientSecret}"
  tenant_id     = "#{azureaccountTenantID}"
  # environment   = "usgovernment" # Uncomment for govcloud
}

provider "azurerm" {
  subscription_id = "#{azureaccountSubscriptionID}"
  client_id       = "#{azureaccountClientID}"
  client_secret   = "#{azureaccountClientSecret}"
  tenant_id       = "#{azureaccountTenantID}"
  # environment         = "usgovernment" # Commented out for Commercial Cloud
  storage_use_azuread = true
  features {}
}

data "azuread_client_config" "current" {

}