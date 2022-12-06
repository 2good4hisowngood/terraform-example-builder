#Virtual Network for Primary Datacenter

resource "azurerm_virtual_network" "vnet1" {
  name                = "${var.client_name}-prod-vnet"
  address_space       = ["10.${var.env_vnet_id}.${var.client_number}.0/25"]
  location            = var.rg1.location
  resource_group_name = var.rg1.name
  dns_servers         = ["10.200.0.4", "10.200.0.5", "10.201.0.4", "10.201.0.5"] #removed from front of list: "10.${var.env_vnet_id}.${var.client_number}.36", "10.${var.env_vnet_id}.${var.client_number}.37", 
  depends_on          = [var.rg1]

  tags = {
    Customer            = "${var.client_name}"
    Environment         = "prod"
    Region              = "${var.primary_region}"
    resource_group_name = "${var.rg1.name}"
  }
}

#Virtual Network for backup Datacenter

resource "azurerm_virtual_network" "vnet2" {
  name                = "${var.client_name}-bckp-vnet"
  address_space       = ["10.${var.env_vnet_id}.${var.client_number}.128/25"]
  location            = var.rg2.location
  resource_group_name = var.rg2.name
  dns_servers         = ["10.200.0.4", "10.200.0.5", "10.201.0.4", "10.201.0.5"]
  depends_on          = [var.rg2]

  tags = local.default_tags
}



#####################################
# Create App Server subnet
#####################################

resource "azurerm_subnet" "app1" {
  name                 = "${var.client_name}-prod-app"
  resource_group_name  = var.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.${var.env_vnet_id}.${var.client_number}.64/26"]
  depends_on           = [azurerm_virtual_network.vnet1]
}

resource "azurerm_network_security_group" "app1nsg" {
  name                = "${var.client_name}-prod-avd-nsg"
  location            = var.primary_region
  resource_group_name = var.rg1.name
  security_rule {
    name                       = "HTTPS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }
  depends_on = [azurerm_subnet.app1]

  tags = local.default_tags
}

resource "azurerm_subnet_network_security_group_association" "app1" {
  subnet_id                 = azurerm_subnet.app1.id
  network_security_group_id = azurerm_network_security_group.app1nsg.id
}

#####################################
# Create avd App Server subnet
#####################################

resource "azurerm_subnet" "app2" {
  name                 = "${var.client_name}-bckp-app"
  resource_group_name  = var.rg2.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes     = ["10.${var.env_vnet_id}.${var.client_number}.192/26"]
  depends_on           = [azurerm_virtual_network.vnet2]
}

# app servers security group
resource "azurerm_network_security_group" "app2" {
  name                = "${var.client_name}-bckp-apps"
  location            = "${local.backup_region}"
  resource_group_name = "${var.rg2.name}"

  security_rule {
    name                       = "allow1433_cross_region_dr_access"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.${var.env_vnet_id}.${var.client_number}.128/25"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow443_cross_region_dr_access"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.${var.env_vnet_id}.${var.client_number}.128/25"
    destination_address_prefix = "*"
  }

  tags = {
    Customer            = "${var.client_name}"
    Service             = "App Servers"
    Environment         = "bckp"
    Region              = "${local.backup_region}"
    resource_group_name = "${var.rg2.name}"
  }
}

#App Server subnet, network security group association
resource "azurerm_subnet_network_security_group_association" "app2" {
  subnet_id                 = "${azurerm_subnet.app2.id}"
  network_security_group_id = "${azurerm_network_security_group.app2.id}"
}



#####################################
#
# Peerings
# First client internal peerings, then AADDS
#####################################

resource "azurerm_virtual_network_peering" "prod2bckp" {
  name                 = "${azurerm_virtual_network.vnet1.name}-to-${azurerm_virtual_network.vnet2.name}"
  resource_group_name  = var.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}

resource "azurerm_virtual_network_peering" "bckp2prod" {
  name                 = "${azurerm_virtual_network.vnet2.name}-to-${azurerm_virtual_network.vnet1.name}"
  resource_group_name  = var.rg2.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
  allow_virtual_network_access = true
  allow_forwarded_traffic = true
  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}

# this will peer in from all the virtual networks tagged with the role of azops
resource "azurerm_virtual_network_peering" "in-primary" {
  count                        = length(var.import_aadds_vnets.resources)
  name                         = "${var.import_aadds_vnets.resources[count.index].name}-to-${azurerm_virtual_network.vnet1.name}"
  remote_virtual_network_id    = azurerm_virtual_network.vnet1.id
  resource_group_name          = split("/", var.import_aadds_vnets.resources[count.index].id)[4]
  virtual_network_name         = var.import_aadds_vnets.resources[count.index].name

  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}

resource "azurerm_virtual_network_peering" "out-primary" {
  count                        = length(var.import_aadds_vnets.resources)
  name                         = "${azurerm_virtual_network.vnet1.name}-to-${var.import_aadds_vnets.resources[count.index].name}"
  remote_virtual_network_id    = var.import_aadds_vnets.resources[count.index].id
  resource_group_name          = var.rg1.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name

  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}

resource "azurerm_virtual_network_peering" "in-secondary" {
  count                        = length(var.import_aadds_vnets.resources)
  name                         = "${var.import_aadds_vnets.resources[count.index].name}-to-${azurerm_virtual_network.vnet2.name}"
  remote_virtual_network_id    = azurerm_virtual_network.vnet2.id
  resource_group_name          = split("/", var.import_aadds_vnets.resources[count.index].id)[4]
  virtual_network_name         = var.import_aadds_vnets.resources[count.index].name

  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}

resource "azurerm_virtual_network_peering" "out-secondary" {
  count                        = length(var.import_aadds_vnets.resources)
  name                         = "${azurerm_virtual_network.vnet2.name}-to-${var.import_aadds_vnets.resources[count.index].name}"
  remote_virtual_network_id    = var.import_aadds_vnets.resources[count.index].id
  resource_group_name          = var.rg2.name
  virtual_network_name         = azurerm_virtual_network.vnet2.name

  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}



resource "azurerm_virtual_network_peering" "in-bastion" {
  count = length(var.import_bastion_vnet.resources)
  name                         = "bastionvnet-to-${azurerm_virtual_network.vnet1.name}"
  remote_virtual_network_id    = azurerm_virtual_network.vnet1.id
  resource_group_name          = split("/", var.import_bastion_vnet.resources[count.index].id)[4]
  virtual_network_name         = var.import_bastion_vnet.resources[count.index].name

  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}

resource "azurerm_virtual_network_peering" "out-bastion" {
  count = length(var.import_bastion_vnet.resources)
  name                         = "${azurerm_virtual_network.vnet1.name}-to-bastionvnet"
  remote_virtual_network_id    = var.import_bastion_vnet.resources[count.index].id
  resource_group_name          = var.rg1.name
  virtual_network_name         = azurerm_virtual_network.vnet1.name

  depends_on = [
    azurerm_virtual_network.vnet1,
    azurerm_virtual_network.vnet2
  ]
}