# Packer image Ubuntu 24.04 LTS
1. Download image to ISO images directory on Proxmox server  - windows server 2022 from https://releases.ubuntu.com/noble/ubuntu-24.04.4-live-server-amd64.iso
2. Rename it to ubuntu-24.04.iso
3. Put your ssh public key into packer\linux directory
4. Change proxmox credentials - IP address proxmox server, proxmox account and password in file config/prod.json

