# --- УМНЫЙ РАСЧЕТ СЕТЕВЫХ ОЧЕРЕДЕЙ ---
locals {
  # Оптимальная эвристика для production:
  # - Половина ядер под сеть (округление вверх)
  # - Лимит 8 (аппаратный максимум virtio-net)
  # - Почему ceil(cores / 2)? Остальные ядра нужны для etcd, kubelet, приложений
  default_queues_per_adapter = min(
    ceil(var.vm_config.cores / 2),
    8
  )
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_config.vm_id
  tags      = ["env-${var.environment}", "managed-by-terraform"]

  clone {
    #vm_id = var.template
    #vm_id = local.template.vmid
    vm_id = local.selected_template.vmid
    full  = true
  }

  cpu {
    cores   = var.vm_config.cores
    sockets = 1
    type    = "host"
  }

  memory { dedicated = var.vm_config.memory }

  disk {
    datastore_id = var.storage_ssd
    interface    = "scsi0"      # best variant
    #interface    = "virtio0"   # not recomendet

    size         = var.vm_config.disk
    #file_format  = "raw"       # we have LVM, not raw files
    discard      = "on"         # Must have settings for SSD
    iothread     = true
    cache        = "none"
    ssd          = true   
  }

  dynamic "disk" {
    for_each = var.vm_config.extra_disk != null ? [1] : []
    content {
      datastore_id = var.storage_ssd
      interface    = "scsi1"
      size         = var.vm_config.extra_disk
      #file_format  = "raw"
      discard      = "on"         # Must have settings for SSD
      iothread     = true
      cache        = "none"
      ssd          = true     
    }
  }

  cdrom {
    interface = "ide0"           # disabling CDROM
    file_id   = "none"
  }

  dynamic "network_device" {
    for_each = var.vm_config.networks
    content {
      bridge = network_device.value.bridge
      model  = "virtio"      

      # Приоритет:
      # 1. Явное значение из terragrunt.hcl (для критичных ролей)
      # 2. Автоматический расчет: min(ceil(cores / 2), 8)
      queues = try(network_device.value.queues, local.default_queues_per_adapter)
    }
  }

  initialization {
    datastore_id = var.storage_hdd
    user_data_file_id = var.cloud_init_id  # Settings cloud init
    interface = "ide2" # Оставьте закомментированным или удалите, если новая версия работает без него
    upgrade = false

    dynamic "ip_config" {
      for_each = var.vm_config.networks
      content {
        ipv4 {
          address = ip_config.value.ip
          gateway = try(ip_config.value.gateway, null)
        }
      }
    }
   
    dynamic "dns" {
	  for_each = try(var.vm_config.dns, null) != null ? [var.vm_config.dns] : []

	  content {
	    servers = dns.value.servers
	    domain  = dns.value.search
	  }
    }
    # Creating user account and import ssh key via Proxmox API
    # This option shows Account name and SSH key on web interface - cloud init panel
    # If you use pure cloud init without Proxmox API, this settings must be turned off
    # because, it's conflicts with pure settings and this option has very small settings than cloud init
    #user_account {
    #  username = var.ansible_user
    #  keys     = [var.ansible_ssh_public_key]
    # }
  }

  agent {
    enabled = true
    type    = "virtio"
    timeout = "5m"
  }

  startup { order = 1 }
}
