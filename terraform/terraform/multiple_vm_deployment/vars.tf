variable "location" {
  type = string
  description = "Region de Azure donde se desplegara la Infraestructura"
  default = "West Europe"
}

variable "vms" {
  type = list(string)
  description = "Maquinas virtuales que se crearan para el despliegue de Kubernetes"
  default = ["master","worker01","worker02"]
}

variable "vm_size" {
  type = list(string)
  description = "Maquinas virtuales que se crearan para el despliegue de Kubernetes"
  default = ["Standard_D2_v2","Standard_D1_v2","Standard_D1_v2"]
}
