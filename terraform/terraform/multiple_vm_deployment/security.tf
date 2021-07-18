# Definicion de un security group y la definicion del trafico que se permitira con sus reglas de seguridad (security_group)
resource "azurerm_network_security_group" "mySecGroup" {
  name                = "sshtraffic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "CP2"
  }
}

# Se asocia el security group a la NIC para permitir el trafico por esa interfaz
resource "azurerm_network_interface_security_group_association" "mySecGroupAssociation" {
  count                     = length(var.vms)
  network_interface_id      = azurerm_network_interface.myNic[count.index].id
  network_security_group_id = azurerm_network_security_group.mySecGroup.id
}
