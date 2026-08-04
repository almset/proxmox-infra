packer {
  required_plugins {
    proxmox = {
      version = ">= 1.2.3"
      source  = "github.com/hashicorp/proxmox"
    }
      windows-update = {
      version = "0.18.3"
      source  = "github.com/rgl/windows-update"
    }
  }
}

# Переменные
variable "proxmox_url" {
  type = string
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
}

variable "winrm_username" {
  type    = string
  default = "Administrator"
}

variable "winrm_password" {
  type      = string
  default   = "P@ssw0rd123!"
  sensitive = true
}

variable "vm_storage" {
  type = string
}

variable "iso_storage" {
  type = string
}

variable "iso_url_windows" {
  type = string
}

# Локальные переменные
locals {
  build_timestamp = formatdate("YYYY-MM-DD-hhmm", timestamp())
  template_name   = "win2022-standard-${local.build_timestamp}"
}

# Source блок для Proxmox
source "proxmox-iso" "windows-2022" {
  # Connection settings
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  node                     = var.proxmox_node
  http_directory = "../../scripts/windows/" 


  # VM settings
  vm_id			   = "9992"
  vm_name                  = local.template_name
  template_description     = "Windows Server 2022 Standard - Built ${local.build_timestamp}"
  
  # Hardware settings
  os           = "win11"
  machine      = "q35"
  memory       = 8192
  ballooning_minimum = 8192
  cores        = 4
  sockets      = 2
  cpu_type     = "x86-64-v2-AES"
  qemu_agent   = true
  # FIX: 10m слишком мало для установки Windows
  task_timeout = "120m"

  bios = "ovmf"
  efi_config {
    efi_storage_pool = var.vm_storage
    efi_type         = "4m"
    # FIX: false — иначе Secure Boot отклоняет кастомный ISO (0xc0000001)
    pre_enrolled_keys = true
  }
  # Disk settings
  scsi_controller = "virtio-scsi-single"
  
  disks {
    disk_size    = "15G"          # Базовый размер для шаблона (Windows займет ~15-18 Гб)
    storage_pool = var.vm_storage
    type         = "scsi"         # Используем scsi, а не virtio
    cache_mode   = "none"         # Безопасно для продакшена (данные сразу на диск)
    discard      = true           # Включает TRIM для Windows
    io_thread    = true           # Повышает производительность
  #  format                = "qcow2"
  }  
  
  # Network settings
  network_adapters {
    model                 = "virtio"
    bridge                = "vmbr0"
    firewall              = false
    # for test if virtio driver absent  model = "e1000"
  }
  
  # ISO and boot settings
  iso_file                 = var.iso_url_windows
  iso_storage_pool         = var.iso_storage
  boot_wait                = "5s"
  boot_command = [
#	"http://{{ .HTTPIP }}:{{ .HTTPPort }}/autounattend.xml"
	"<enter>"
  ]

  boot_iso {
     type         = "ide"
     iso_file     = "local-hdd-wd2tb:iso/windows_server_2025_en.iso"
     iso_checksum = "none"
     unmount      = true
  }


  
  # Additional drivers
  additional_iso_files {
    device                = "ide1"
    index 		  = 1
    iso_file              = "local-hdd-wd2tb:iso/virtio-win.iso"
    iso_storage_pool      = var.iso_storage
    unmount               = true
  }

  # ide1 — autounattend.xml (index=1 → ide1)
  additional_iso_files {
    device	     = "ide2"
    type             = "ide"
    index            = 2
    iso_storage_pool = var.iso_storage
    unmount          = true
    keep_cdrom_device = false
    cd_files = [
      "${path.root}/../../scripts/windows/autounattend.xml",
      "${path.root}/../../scripts/windows/drivers/**"
    ]
    #cd_label = "cidata"
    cd_label = "WIN_SETUP"
  }

  
  # WinRM configuration
  communicator   = "winrm"
#  winrm_username           = "Administrator"
#  winrm_password           = "P@ssw0rd123!"
  winrm_username = var.winrm_username
  winrm_password = var.winrm_password
  winrm_port               = 5985
  winrm_use_ssl            = false
  winrm_insecure           = true
  winrm_timeout            = "2h"
  
  # Unmount ISO after build
  unmount_iso              = true
  
  # Skip adding of a cloud-init drive
  cloud_init               = false
}
build {
  sources = ["source.proxmox-iso.windows-2022"]
  
  # Этап 1: Базовое конфигурирование после установки
  provisioner "powershell" {
    script = "../../scripts/windows/initial-setup.ps1"
  }

  # Этап 2: Перезагрузка через Packer (правильный способ)
  provisioner "windows-restart" {
    restart_timeout = "10m"
    check_registry  = true
  }
  
 # Этап 2.2: Установка драйверов virtio
 # Пропускаем потому-что драйвер ставится по время установки Windows
 # provisioner "powershell" {
 #   script = "../../scripts/windows/install-virtio.ps1"
 # }
  
 # Этап 2.3: Установка Python для Ansible - этап не нужен так как Powershell over SSH, Python есть уже в CloudBase-init
 #   provisioner "powershell" {
 #     script = "../../scripts/windows/install-python.ps1"
 #  }
  
  # Этап 4: Windows updates (опционально)
  provisioner "windows-update" {
    search_criteria = "IsInstalled=0"
    filters = [
      # Исключить Preview обновления
      "exclude:$_.Title -like '*Preview*'",
      # Исключить 26GB кумулятивный апдейт если не нужен
      "exclude:$_.Title -like '*Cumulative Update for Microsoft server*'",
      "include:$true",
    ]
    update_limit = 25
  }
  # Этап 5: Hardening и очистка перед sysprep
  provisioner "powershell" {
    script = "../../scripts/windows/harden-and-clean.ps1"
  }
 
 # # Копируем публичный ключ в шаблон (дубль)
 # provisioner "file" { 
 #       source = "./id_rsa.pub" 
 #       destination = "C:/ProgramData/ssh/administrators_authorized_keys" 
 # }

  # Установка OpenSSH
  provisioner "powershell" {
    script = "../../scripts/windows/install-openssh.ps1"
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
  }
  # Копируем публичный ключ в шаблон - этот этап конфликтует с Cloud-init, отключаем, так как CI будет импортировать ключ
#  provisioner "file" { 
#	source = "./id_rsa.pub" 
#	destination = "C:/ProgramData/ssh/administrators_authorized_keys" 
#  }

  # Установка Cloudbase-Init
  provisioner "powershell" {
    script = "../../scripts/windows/install-cloudbase-init.ps1"
    elevated_user     = var.winrm_username
    elevated_password = var.winrm_password
  }
  
  # Копирование конфигурации Cloudbase-Init
  provisioner "file" {
    source      = "../../scripts/windows/cloudbase-init/"
    destination = "C:\\Program Files\\Cloudbase Solutions\\Cloudbase-Init\\conf\\"
  } 

  # Этап 6: Sysprep (ОЧЕНЬ ВАЖНО - последний шаг)
 provisioner "powershell" {
   inline = [
     "Write-Host 'Running sysprep...'",
     "Start-Process -FilePath 'C:\\Windows\\System32\\Sysprep\\sysprep.exe' -ArgumentList '/generalize /oobe /mode:vm /shutdown /quiet' -Wait"
   ]
  }
}

