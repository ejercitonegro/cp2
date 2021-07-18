# Definicion de una VM
## Se define el virtual hardware de la misma
## Se asigna la NIC creada anteriormente con sus security rule
## Usuario administrador -> se utiliza la clave privada
## Se define el tipo de disco y su replicacion
### LRS -> Locally Redundant Storage
## Definicion de la imagen a utilizar
## storage account -> almacenamiento de informacion de troubleshooting

resource "azurerm_linux_virtual_machine" "myVM1" {
  name                            = "VM1"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  size                            = var.vm_size
  admin_username                  = "adminUsername"
  network_interface_ids           = [ azurerm_network_interface.myNic1.id ]
  disable_password_authentication = true

  admin_ssh_key {
    username   = "adminUsername"
    public_key = file("/home/pablo/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name      = "centos-8-stream-free"
    product   = "centos-8-stream-free"
    publisher = "cognosys"
  }
  
  source_image_reference {
    publisher = "cognosys"
    offer     = "centos-8-stream-free"
    sku       = "centos-8-stream-free"
    version   = "1.2019.0810"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystAccount.primary_blob_endpoint
  }

  tags = {
    environment = "CP2"
  }
}
