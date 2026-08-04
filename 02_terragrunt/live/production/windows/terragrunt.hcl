terraform {
   # // - this 2 slashes for mark stacks/infrastructure dir as root
   source = "../../..///stacks/infrastructure"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "env" {
  path   = find_in_parent_folders("env.hcl")
  expose = true
}

inputs = merge(
  include.env.inputs,
  {
    template = "windows-2022"
    ansible_user = "ansible"
    ansible_ssh_public_key = file(find_in_parent_folders("secrets/ansible_key.pub"))
	# VM Configurations
		# VM Configurations
vm_configs = {
  "dc-prod-01" = {
    vm_id  = 300
    platform = "windows"
    role = "ad"

    cores  = 2
    memory = 4048
    disk   = 30
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.10/24", gateway = "192.168.100.6", queues = 2 }
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }
  }
  
  "fs-prod-01" = {
    vm_id  = 303
    platform = "windows"
    role = "fs"

    cores  = 2
    memory = 4048
    disk   = 25
    extra_disk = 50
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.13/24", gateway = "192.168.100.6", queues = 2  }
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }
  }
}

}

)

