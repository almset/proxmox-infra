output "vm_id" { 
	value = proxmox_virtual_environment_vm.vm.vm_id 
}

output "platform" {
  	value = var.vm_config.platform
}

output "role" {
  	value = var.vm_config.role
}

output "ip_addresses" {
  value = {
    external_ip = try(split("/", proxmox_virtual_environment_vm.vm.initialization[0].ip_config[0].ipv4[0].address)[0], "")
    internal_ip = try(length(proxmox_virtual_environment_vm.vm.initialization[0].ip_config) > 1 ? split("/", proxmox_virtual_environment_vm.vm.initialization[0].ip_config[1].ipv4[0].address)[0] : "", "")
  }
}
