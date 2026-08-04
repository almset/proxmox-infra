# Packer image Windows 2022 
1. Download image to ISO images directory on Proxmox server  - windows server 2022 from https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022
2. Rename it to windows_server_2022_en.iso
3. Put your ssh public key into packer\windows directory
4. Change proxmox credentials - IP address proxmox server, proxmox account and password in file config/prod.json

