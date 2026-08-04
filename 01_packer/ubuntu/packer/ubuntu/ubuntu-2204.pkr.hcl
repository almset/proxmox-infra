packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" { type = string }
variable "proxmox_username" { type = string }
variable "proxmox_password" { 
	type = string 
	sensitive = true 
}
variable "proxmox_node" { type = string }
variable "vm_storage" { type = string }
variable "iso_storage" { type = string }
variable "iso_url_ubuntu" { type = string }

locals {
  timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
#  ssh_public_key = trimspace(file("id_rsa.pub"))
}

source "proxmox-iso" "ubuntu-2204" {
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  
  vm_id 		   = 9991
  vm_name                  = "ubuntu-2204-base-${local.timestamp}"
  template_name            = "ubuntu-2204-base-template"
  template_description     = "Ubuntu 22.04 Base - Built ${local.timestamp}"
  
  cores                    = 2
  cpu_type 		   = "x86-64-v2-AES"
  memory                   = 2048
  ballooning_minimum 	   = 2048
  machine 		   = "q35"
  os                       = "l26"
  qemu_agent               = true
  
  # Disk settings
  scsi_controller 	   = "virtio-scsi-single"
  disks {
    disk_size             = "10G"
    type                  = "scsi"
    storage_pool 	  = var.vm_storage

    io_thread  = true
    discard    = true
    cache_mode = "none"
    
  }

  cloud_init = true
  cloud_init_storage_pool = var.iso_storage
  
  network_adapters {
    model                 = "virtio"
    bridge                = "vmbr0"
    packet_queues	  = 2         # Improving network speed for 2 cores CPU, in future this parametr will changed by terraform
  }
  boot_iso {
    type         = "ide"
    iso_file     = var.iso_url_ubuntu
  }
  boot_wait                = "3s"
  boot_command = [
    "<esc><wait>",
    "e<wait><down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---",    
    "<f10><wait>"
  ]

  
  http_directory           = "../../scripts/ubuntu/http"
  http_port_min            = 8800
  http_port_max            = 8900
  
  ssh_username             = "packer"
  ssh_password             = "P@ssw0rd123!"
  ssh_timeout              = "20m"
  
}

build {
  sources = ["source.proxmox-iso.ubuntu-2204"]
  
  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 5; done",
      "sleep 10"
    ]
  }
  
  # Только базовое обновление, без лишнего
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y qemu-guest-agent cloud-init",
      "sudo systemctl enable qemu-guest-agent"
    ]
  }
  
  # Очистка перед шаблоном
  provisioner "shell" {
    inline = [
    "sudo apt-get clean",
    "sudo apt-get autoremove -y",
    "sudo cloud-init clean --logs --seed",
    "sudo truncate -s 0 /etc/machine-id",
    "sudo rm -f /var/lib/dbus/machine-id",
    "sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id",
    "sudo rm -rf /tmp/* /var/tmp/*"
  ]

  }
}

