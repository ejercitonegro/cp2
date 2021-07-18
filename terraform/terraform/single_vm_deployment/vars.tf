variable "location" {
  type = string
  description = "Region de Azure donde se desplegara la Infraestructura"
  default = "West Europe"
}

variable "vm_size" {
  type = string
  description = "Caracteristicas de Virtual Hardware de la maquina"
  default = "Standard_D1_v2"
}
