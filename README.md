# Promxox virtual infrastructure

This project describes automation for proxmox server with base IAC instrument such as:
1. Packer (Is needed to create tempates for Linux or Windows machines with packages node exporter, wazuh, vault, zabbix and base hardening)
2. Terragrunt/Terraform (Creating infrastgructure virtual machines, example DNS server Bind, Gateway with iptables and other )
3. Ansible (infrstructure servers such as dns server, gateway, base roles)
4. Ansible K8s cluster (just installing cluster with configuring ArgoCD remote URL)

Details:
- Packer: used to create templates Ubuntu Server and Windows Server
- Terragrunt: create VM's from templates, you can create VM list to easy deploy
- Ansible: automaticaly configures created VM's - dns server, gateway, base operations such as updating, firewall for opening or closing ports on VM's and etc...
- Ansible k8s playbook creating cluster with argocd, you can push your remote url in to ansible config for automaticaly deploy needed cluster configuration
