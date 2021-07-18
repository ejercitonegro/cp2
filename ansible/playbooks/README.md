# PLAYBOOKS
step_1.yaml -> Configuracion inical de las VM (Rol de ansible -> initial_configuration)
step_2.yaml -> Despliegue del servidor nfs (Rol de ansible -> deploy_nfs)
step_3.yaml -> Configuracion comun en todos los nodos (Rol de ansible -> common_tasks)
step_4.yaml -> Configuracion especifica del nodo master y posterior despliegue de kubernetes (Rol de ansible -> configure_master)
step_5.yaml -> Configuracion especifica de loss nodos workes y union al cluster de kubernetes (Rol de ansible -> postconfigure_workers)
step_6.yaml -> Playbook encargado de configurar los nodos workers y master para el posterior despliegue en el master del ingress controller.
step_7.yaml -> Creación de un usuario no administrador
