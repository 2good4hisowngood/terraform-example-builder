
#####################################
# Create web Server subnet
#####################################

resource "azurerm_subnet" "web" {
  name                 = "${var.client_name}-prod-web"
  resource_group_name  = var.rg1.name
  virtual_network_name = var.vnet1.name
  address_prefixes     = ["10.250.${var.client_number}.56/29"]
}

# web server
resource "azurerm_network_security_group" "web" {
  name                = "${var.client_name}-prod-web"
  location            = var.rg1.location
  resource_group_name = var.rg1.name
  depends_on          = [azurerm_subnet.web]

  security_rule {
    name                       = "allow_cross_region_dr_access"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.250.${var.client_number}.128/25"
    destination_address_prefix = "*"
  }

  tags = {
    Customer            = "${var.client_name}"
    Service             = "web Server"
    Environment         = "prod"
    Region              = "${var.rg1.location}"
    resource_group_name = "${var.rg1.name}"
  }
}

#web server subnet, network security group association
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
  depends_on = [
    azurerm_subnet.web,
    azurerm_network_security_group.web
  ]
}

#####################################
# Create web Server subnet
#####################################

resource "azurerm_subnet" "web2" {
  name                 = "${var.client_name}-bckp-web"
  resource_group_name  = var.rg2.name
  virtual_network_name = var.vnet2.name
  address_prefixes     = ["10.250.${var.client_number}.184/29"]
}

#web server
resource "azurerm_network_security_group" "web2" {
  name                = "${var.client_name}-bckp-web"
  location            = "${var.rg2.location}"
  resource_group_name = "${var.rg2.name}"

  tags = {
    Customer            = "${var.client_name}"
    Service             = "web Server"
    Environment         = "bckp"
    Region              = "${var.rg2.location}"
    resource_group_name = "${var.rg2.name}"
  }
}

#web server subnet, network security group association
resource "azurerm_subnet_network_security_group_association" "web2" {
  subnet_id                 = "${azurerm_subnet.web2.id}"
  network_security_group_id = "${azurerm_network_security_group.web2.id}"
}