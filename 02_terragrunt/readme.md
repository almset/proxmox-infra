## Step 2 - Terragrunt

  - Change Proxmox password in live/production/env.hcl
  - Change Gitlab remote state password in live/root.hcl
  - Go to the directory live/production/linux/ and change terragrunt.hcl - add or remove VM's
  - Deploy Linux VM's, go to directory and run /scripts/start.sh linux
  - Go to the directory live/production/windows/ and change terragrunt.hcl - add or remove VM's
  - Deploy Windows VM's, go to directory and run /scripts/start.sh windows
