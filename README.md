# Promxox virtual infrastructure

This project describes automation for proxmox server with base IAC instrument such as:
1. Packer
2. Terrafunt (terraform)
3. Ansible

Details:
- Packer: used to create templates Ubuntu Server and Windows Server
- Terragrunt: create VM's from templates, you can create VM list to easy deploy
- Ansible: automaticaly configures created VM's - dns server, gateway, base operations, firewall ...
