# Configuracion del provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "=2.46.1"
    }
  }
}

# Credenciales de conexion del provider a traves del service principal creado anteriormente
provider "azurerm" {
  features {}
  subscription_id = "d89ae854-96c9-4b68-a01a-d0dbc5667745"
  client_id = "b6c49a44-8b96-44c1-96c1-8807b60e63f5"
  client_secret = "ZdFd.SyH-fs_WE3h2a4PS-.8WKSM4VDyYL"
  tenant_id = "899789dc-202f-44b4-8472-a6d40f9eb440"
}

# Creacion de grupo de recursos
resource "azurerm_resource_group" "rg" {
    name     = "kubernetes_rg"
    location = var.location

    tags = {
        environment = "CP2"
    }
}

# Creacion de storage account dentro del grupo de recursos anteriormente generado
resource "azurerm_storage_account" "mystAccount" {
    name                     = "studentstorageaccountcp2"
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"

    tags = {
        environment = "CP2"
    }
}
