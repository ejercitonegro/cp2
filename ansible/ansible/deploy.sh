#!/bin/bash

# Leer y procesar argumentos
OPTS=`getopt -o d: --long disk: -n 'parse-options' -- "$@"`

# Comprobamos que el procesado de argumentos ha sido exitoso
if [ $? != 0 ] ; then
	echo -e "\n\033[31mERROR - \033[0m Error en el parseo de los parámetros de entrada."
	exit 1
fi

eval set -- "$OPTS"

unset DISK_GB
REGEX='^[0-9]+$'
TERRAFORM_PATH="/home/pablo/terraform/multiple_vm_deployment"
PLAYBOOK_PATH="/home/pablo/ansible/playbooks"

# Bucle de argumentos y asignacion a variables
while true; do
  case "$1" in
        -d | --disk ) DISK_GB="$2"; shift ;;
        -- ) shift; break ;;
        * ) break ;;
  esac
done

# Comprobamos si el valor introducido para el tamanio del disco y almacenado en la variable DISK_GB es un numero unicamente
if ! [[ ${DISK_GB} =~ ${REGEX} ]] ; then
        echo -e "\n\033[31mERROR - \033[0m El tamanio de disco introducido no es un numero."
        exit 1
fi

# FUNCIONES
debug_echo() {
	echo -e "\n\033[33mDEBUG - ${PROGNAME}\033[0m   -- DEBUG -- ${1}\n"
}

graceful_echo() {
	echo -e "\n\033[32mSUCCESS - ${PROGNAME}\033[0m   -- SUCCESS -- ${1}\n"
}

error_echo() {
	echo -e "\n\033[31mERROR - ${PROGNAME}\033[0m   --  ERROR  -- ${1}\n" >&2
}

error_exit() {
	echo -e "\n\033[31mERROR - ${PROGNAME}\033[0m   --  ERROR  -- ${1:-"Unknown Error"}\n" >&2
	exit 1
}

graceful_exit() {
	echo -e "\n\033[32mSUCCESS - ${PROGNAME}\033[0m   -- SUCCESS -- ${1}\n"
	exit 0
}


# MAIN
main() {

	debug_echo "Desplegando infraestuctura con terraform."
	# Despliegue de la infraestructura con terraform lanzado con ansible
        if ! ansible-playbook "${PLAYBOOK_PATH}/terraform.yaml" --tags terraform_apply -e "terraform_path=${TERRAFORM_PATH}"; then
                error_exit "ANSIBLE - Se ha producido un error en el despliegue de la infraestructura con ansible."
        fi
        graceful_echo "ANSIBLE - Despliegue de la infraestructura con terraform realizado con exito."

	debug_echo "Tamanio de disco seleccionado: ${DISK_GB}G"	

	debug_echo "Otorgando nuevo disco al nodo master para despliegue del nfs..."
	# Nuevo disco para la VM para el posterior despliegue del servidor nfs
	if ! az vm disk attach --new --resource-group kubernetes_rg --size-gb "${DISK_GB}" --sku Standard_LRS --vm-name vm-master --name disco_nfs; then
		error_exit "Se ha producido un error a la hora de anadir un nuevo disco al nodo nfs."
	fi
	graceful_echo "Proceso para el nuevo disco para el nodo nfs finalizado con exito."

	debug_echo "ANSIBLE - Configuracion inicial de los futuros nodos de kubernetes..."
	# Configuracion inicial de las VM
	if ! ansible-playbook -u adminUsername -i hosts "${PLAYBOOK_PATH}/step_1.yaml"; then
		error_exit "ANSIBLE - Se ha producido un error en la configuracion inicial sobre todos los nodos."
	fi
	graceful_echo "ANSIBLE - Configuracion inicial en todos los nodos realizada con exito."


	debug_echo "ANSIBLE - Esperando a la disponibilidad de los nodos despues del reinicio..."
        # Configuracion inicial de las VM
        if ! ansible-playbook -u adminUsername -i hosts "${PLAYBOOK_PATH}/wait_for.yaml"; then
                error_exit "ANSIBLE - Se ha producido un error en la espera por la disponibilidad de los nodos."
        fi
        graceful_echo "ANSIBLE - Nodos disponibles tras su actualizacion y posterior reinicio."

	debug_echo "ANSIBLE - Desplegando nodo nfs..."
	# Despliegue del servidor NFS
	if ! ansible-playbook -u adminUsername -i hosts --limit master "${PLAYBOOK_PATH}/step_2.yaml" -e "disk_gb=${DISK_GB}"; then
		error_exit "ANSIBLE - Se ha producido un error en el proceso de despliegue del nodo NFS."
	fi
	graceful_echo "ANSIBLE - Nodo NFS desplegado con exito."

	debug_echo "ANSIBLE - Postconfiguracion comun sobre los nodos master y workers..."
	# Tareas comunes de configuracion en todos los nodos
	if ! ansible-playbook -u adminUsername -i hosts --limit master,workers "${PLAYBOOK_PATH}/step_3.yaml"; then
		error_exit "ANSIBLE - Se ha producido un error en el proceso de postconfiguracion de los nodos master y workers."
	fi
	graceful_echo "ANSIBLE - Postconfiguracion de los nodos master y workers realizado con exito."

	debug_echo "ANSIBLE - Configurando y desplegando el cluster de kuberntes sobre el nodo master..."
	# Configuracion del master y despliegue de kubernetes
	if ! ansible-playbook -u adminUsername -i hosts --limit master "${PLAYBOOK_PATH}/step_4.yaml"; then
		error_exit "ANSIBLE - Se ha producido un error en el proceso de configuracion y despliegue del cluster de kubernetes sobre el nodo master."
	fi
	graceful_echo "ANSIBLE - Configuracion y despliegue del cluster de kubernetes realizado con exito."

	debug_echo "ANSIBLE - Uniendo nodos al cluster de kubernetes..."
        # Union de nodos al cluster
        if ! ansible-playbook -u adminUsername -i hosts --limit workers "${PLAYBOOK_PATH}/join_cluster.yaml"; then
                error_exit "ANSIBLE - Se ha producido un error en el procso de union de los nodos al cluster de kubernetes."
        fi
        graceful_echo "ANSIBLE - Nodos unidos con exito con exito."

	debug_echo "ANSIBLE - Desplegando SDN azure..."
	# Despliegue de la SDN en Azure
	if ! ansible-playbook -u adminUsername -i hosts --limit master "${PLAYBOOK_PATH}/step_5.yaml"; then
		error_exit "ANSIBLE - Se ha producido un error en el despliegue de la SDN de azure."
	fi
	graceful_echo "ANSIBLE - SDN de azure desplegada con exito."

	debug_echo "ANSIBLE - Postconfiguracion y despliegue del ingress controller..."
	# Post-Configuracion de los workers y master y despliegue del ingress controller
	if ! ansible-playbook  -i hosts  "${PLAYBOOK_PATH}/step_6.yaml"; then
		error_exit "ANSIBLE - Se ha producido un error en los procesos de postconfiguracion y despliegue del ingress controller."
	fi
	graceful_echo "ANSIBLE - Postconfigurando y despliegue del ingress controller realizado con exito."
	
	debug_echo "ANSIBLE - Creacion de usuario no-admin para la gestion del cluster de kubernetes..."
	# Creacion de usuario no-admin
	if ! ansible-playbook  -i hosts  "${PLAYBOOK_PATH}/step_7.yaml"; then
		error_exit "ANSIBLE - Se ha producido un error en la generacion del usuario no-admin."
	fi
	graceful_echo "ANSIBLE - Usuario no-admin generado con exito."

        debug_echo "ANSIBLE - Montando NFS..."
        # Montaje de nfs
        if ! ansible-playbook -u adminUsername -i hosts --limit workers "${PLAYBOOK_PATH}/mount_nfs.yaml"; then
                error_exit "ANSIBLE - Se ha producido un error en el proceso de montaje de los NFS."
        fi
        graceful_echo "ANSIBLE - NFS montados con exito."

	debug_echo "ANSIBLE - Desplegando httpd.."
        # Montaje de nfs
        if ! ansible-playbook -u adminUsername -i hosts --limit master "${PLAYBOOK_PATH}/step_8.yaml"; then
                error_exit "ANSIBLE - Se ha producido un error en el proceso de despliegue del httpd."
        fi
        graceful_echo "ANSIBLE - httpd desplegado con exito."

	graceful_exit "Kubernetes desplegado con exito."
}

main
