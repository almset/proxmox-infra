# Promxox virtual infrastructure

This project describes automation for proxmox server with base IAC instruments such as:
1. Packer (Is needed to create tempates for Linux or Windows machines with packages node exporter, wazuh, vault, zabbix and base hardening)
2. Terragrunt/Terraform (Creating infrastgructure virtual machines from packer templates, example DNS server Bind, Gateway with iptables and others)
3. Ansible (automaticaly configure infrstructure servers such as dns server, gateway, basic cluster k8s rke2 or kubeadm,  base role for installing and updating your usefull packages)
4. Ansible K8s platform (just installing and configuring ArgoCD with your remote URL gitops configuration, you can find example config in subfolder 02-gitops)

Details:
- Folder Packer: used to create templates Ubuntu Server and Windows Server
- Folder Terragrunt: create VM's from templates, you can create VM list to easy deploy
- Folder Ansible: automaticaly configures created VM's - dns server, k8s-master and worker nodes, gateway, base operations such as updating, firewall for opening or closing ports on VM's and etc...
- Folder Ansible k8s platform: installing argocd, you can push your remote url in to ansible config for automaticaly deploy needed cluster configuration. 
