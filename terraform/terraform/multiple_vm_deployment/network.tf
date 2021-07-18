# Creacion de red virtual sobre el grupo de recursos
resource "azurerm_virtual_network" "myNet" {
  name                = "kubernetesnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
      environment = "CP2"
  }
}

# Creacion de una subnet dentro de la red virtual creada anteriormente
resource "azurerm_subnet" "mySubnet" {
  name                 = "terraformsubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.myNet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Creamos una interfaz de red con sus caracteristicas propias
resource "azurerm_network_interface" "myNic" {
  name                = "vmnic${var.vms[count.index]}"
  count               = length(var.vms)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconf${var.vms[count.index]}"
    subnet_id                     = azurerm_subnet.mySubnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.${count.index + 10}"
    public_ip_address_id          = azurerm_public_ip.myPublicIp[count.index].id
  }

  tags = {
      environment = "CP2"
  }
}

# Creacion de zona
resource "azurerm_dns_zone" "kubernetesDomain" {
  name                = "kubernetesdomain.com"
  resource_group_name = azurerm_resource_group.rg.name
}

# Creacion de la IP publica a utilizar por la NIC
resource "azurerm_public_ip" "myPublicIp" {
  name                = "vmip${var.vms[count.index]}"
  count               = length(var.vms)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  domain_name_label   = "vm-${var.vms[count.index]}"
  sku                 = "Basic"

  tags = {
      environment = "CP2"
  }
}
