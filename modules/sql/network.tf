#####################################
# Create SQL subnet
#####################################

resource "azurerm_subnet" "sql" {
  name                 = "${var.client_name}-prod-SQL"
  resource_group_name  = var.rg1.name
  virtual_network_name = var.vnet1.name
  address_prefixes     = ["10.250.${var.client_number}.48/29"]
  depends_on           = [var.vnet1]
}

# sql
resource "azurerm_network_security_group" "sql" {
  name                = "${var.client_name}-prod-SQL"
  location            = var.rg1.location
  resource_group_name = var.rg1.name
  depends_on          = [azurerm_subnet.sql]

    security_rule {
    name                       = "allow_cross_region_dr_access"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "10.250.${var.client_number}.128/25"
    destination_address_prefix = "*"
  }

  tags = {
    Customer            = "${var.client_name}"
    Service             = "SQL"
    Environment         = "prod"
    Region              = "${var.rg1.location}"
    resource_group_name = "${var.rg1.name}"
  }
}

#sql subnet, network security group association
resource "azurerm_subnet_network_security_group_association" "sql" {
  subnet_id                 = azurerm_subnet.sql.id
  network_security_group_id = azurerm_network_security_group.sql.id
}

#####################################
# Create SQL subnet
#####################################

resource "azurerm_subnet" "sql2" {
  name                 = "${var.client_name}-bckp-sql"
  resource_group_name  = var.rg2.name
  virtual_network_name = var.vnet2.name
  address_prefixes     = ["10.250.${var.client_number}.176/29"]
  depends_on           = [var.vnet2]
}

#sql
resource "azurerm_network_security_group" "sql2" {
  name                = "${var.client_name}-bckp-sql"
  location            = "${var.rg2.location}"
  resource_group_name = "${var.rg2.name}"


  tags = {
    Customer            = "${var.client_name}"
    Service             = "sql"
    Environment         = "bckp"
    Region              = "${var.rg2.location}"
    resource_group_name = "${var.rg2.name}"
  }
}


#sql subnet, network security group association
resource "azurerm_subnet_network_security_group_association" "sql2" {
  subnet_id                 = "${azurerm_subnet.sql2.id}"
  network_security_group_id = "${azurerm_network_security_group.sql2.id}"
}