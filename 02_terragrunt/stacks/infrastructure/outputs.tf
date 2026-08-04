output "inventory" {
  description = "Inventory for Ansible"
  value = merge(
    {
     for name, vm in module.vm_regular :
      name => {
        vm_id = vm.vm_id
	ansible_host = (
	  try(vm.ip_addresses.internal_ip, "") != ""
	    ? vm.ip_addresses.internal_ip
	    : vm.ip_addresses.external_ip
	)
        management_ip = vm.ip_addresses.external_ip
        role = vm.role
        platform = vm.platform
        environment = var.environment
      }
    },
  )
}
