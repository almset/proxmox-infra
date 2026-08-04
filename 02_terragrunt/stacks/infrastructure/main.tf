module "network" {
  source       = "../../modules/network"
  proxmox_node = var.proxmox_node
}

locals {
  regular_vms = var.vm_configs
}

# На будущее - for the future
#locals {
#    bastion = {
#      for k,v in var.vm_configs :
#      k => v
#      if v.role=="bastion"
#    }
#    routers = {
#      for k,v in var.vm_configs :
#      k=>v
#      if v.role=="router"
#    }
#    workers = {
#      for k,v in var.vm_configs :
#      k=>v
#      if v.role=="worker"
#    }
#}


module "cloud_init_regular" {
  source   = "../../modules/cloud-init"
  for_each = local.regular_vms

  vm_name                     = each.key
  ansible_user                = var.ansible_user
  ansible_ssh_public_key      = var.ansible_ssh_public_key
  storage_hdd                 = var.storage_hdd
  proxmox_node                = var.proxmox_node
}

module "vm_regular" {
  source   = "../../modules/vm"
  for_each = local.regular_vms

  vm_name                   = each.key
  vm_config                 = each.value
  template	            = var.template
  proxmox_node              = var.proxmox_node
  storage_ssd               = var.storage_ssd
  storage_hdd               = var.storage_hdd
  environment               = var.environment
  cloud_init_id             = module.cloud_init_regular[each.key].id
  ansible_user              = var.ansible_user
  ansible_ssh_public_key    = var.ansible_ssh_public_key

  depends_on = [module.cloud_init_regular]
}

