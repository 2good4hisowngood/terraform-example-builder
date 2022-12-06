variable "admin_password" {
}
variable "admin_username" {
}
variable "client_name" {  
}
variable "client_number" {  
}
variable "domain_name" {
}
variable "domain_user_upn" {  
}
variable "ou_path" {
}
variable "web_count" {
  
}




# Import from other modules, set in main.tf
variable "default_tags" {
  default = ""
}
variable "scripts_account" {
  default = ""
}
variable "rg1" {  
}
variable "rg2" {  
}
variable "rv1" {  
}
variable "rv2" {  
}
variable "vnet1" {  
}
variable "vnet2" {  
}
variable "web_vm_size" {  
}
variable "timezone" {
}
variable "vm_tags" {  
}
variable "sql_web_tags" {
}
variable "test_enabled" {
}
variable "peering_out" {
}
variable "peering_in" {
}
# variable "setup-web" {}
variable "bp1" {
  
}
variable "site_replication_policy" {
}
variable "recovery_container_primary" {
}
variable "fabric_primary" {
}
variable "fabric_secondary" {
}
variable "recovery_container_secondary" {
}
variable "recovery_storage_cache" {  
}
variable "web_tags" {
  
}




locals {
  default_tags = var.default_tags
  vm_tags = var.vm_tags
  sql_web_tags = var.sql_web_tags
  test_enabled = var.test_enabled
}