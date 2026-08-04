inputs = {

  environment = "production"

  proxmox_api_url  = "https://10.0.10.200:8006/api2/json"
  proxmox_username = "terraform@pam"
  proxmox_password = "YOUR_PASSWORD_JERE"

  proxmox_node = "pve-prod-01"

  storage_ssd = "local-ssd-seagate2tb"
  storage_hdd = "local-hdd-wd2tb"

}
