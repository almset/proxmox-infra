terraform {
  # // - Terragrunt отмечает нужный подкаталог как корневой модуль.
  # // - use this keys for run midle directory as root
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
    template = "ubuntu-22"
    ansible_user = "ansible"
    #ansible_ssh_public_key_path = "secrets/ansible_key.pub"
    ansible_ssh_public_key = file(find_in_parent_folders("secrets/ansible_key.pub"))
    
    # VM Configs
	# VM Configurations
vm_configs = {
  "bastion-prod-01" = {
    vm_id  = 200
    platform = "linux"
    role = "bastion"

    cores  = 2
    memory = 2048
    disk   = 20
    networks = [
      { bridge = "vmbr0", ip = "10.0.10.5/24", gateway = "10.0.10.1", queues = 1 },
      { bridge = "vmbr1", ip = "192.168.100.5/24", gateway = null, queues = 1 }
    ]
    dns = {
      servers = ["10.0.10.1"]
      search  = "local"
    }
  }
  
  "router-prod-01" = {
    vm_id  = 202
    platform = "linux"
    role = "router"

    cores  = 2
    memory = 2048
    disk   = 10
    networks = [
      { bridge = "vmbr0", ip = "10.0.10.6/24", gateway = "10.0.10.1" },
      { bridge = "vmbr1", ip = "192.168.100.6/24", gateway = null }     
    ]    
    dns = {
      servers = ["10.0.10.1"]
      search  = "local"
    }

  }
  
  "dns-prod-01" = {
    vm_id  = 201
    platform = "linux"
    role = "dns"

    cores  = 2
    memory = 2048
    disk   = 10
    networks = [
      { bridge = "vmbr0", ip = "10.0.10.7/24", gateway = "10.0.10.1" },
      { bridge = "vmbr1", ip = "192.168.100.7/24", gateway = null }
    ]
    dns = {
      servers = ["10.0.10.1"]
      search  = "local"
    }
  }
  
  "master-k8s-prod-01" = {
    vm_id  = 220
    platform = "linux"
    role = "k8s-master"

    cores  = 4
    memory = 8192
    disk   = 60
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.20/24", gateway = "192.168.100.6" }
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }
  }
  
  "worker-k8s-prod-01" = {
    vm_id  = 221
    platform = "linux"
    role = "k8s-worker"

    cores  = 4
    memory = 12288
    disk   = 60
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.21/24", gateway = "192.168.100.6"}
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }

  }
  
  "worker-k8s-prod-02" = {
    vm_id  = 222
    platform = "linux"
    role = "k8s-worker"

    cores  = 4
    memory = 12288
    disk   = 60  
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.22/24", gateway = "192.168.100.6" }
    ]
    dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }

  }

  "haproxy-prod-01" = {
    vm_id  = 203
    platform = "linux"
    role = "haproxy"
    
    cores  = 2
    memory = 2048
    disk   = 10
    networks = [
      { bridge = "vmbr0", ip = "10.0.10.8/24", gateway = "10.0.10.1" },
      { bridge = "vmbr1", ip = "192.168.100.100/24", gateway = null }
    ]
    dns = {
      servers = ["10.0.10.1"]
      search  = "local"
    }

  }
  
  "jenkins-prod-01" = {
    vm_id  = 230    
    platform = "linux"
    role = "jenkins"
    
    cores  = 4
    memory = 4096
    disk   = 40
    extra_disk = 50
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.30/24", gateway = "192.168.100.6" }
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }

  }
  
  "nexus-prod-01" = {
    vm_id  = 231
    platform = "linux"
    role = "nexus"

    cores  = 4
    memory = 4096
    disk   = 20
    extra_disk = 100
    networks = [
      { bridge = "vmbr1", ip = "192.168.100.31/24", gateway = "192.168.100.6"  }
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }

  }
  
  "monitoring-prod-01" = {
    vm_id  = 240
    platform = "linux"
    role = "monitoring"
     
    cores  = 4
    memory = 4096
    disk   = 40
    extra_disk = 100

    networks = [
      { bridge = "vmbr1", ip = "192.168.100.40/24", gateway = "192.168.100.6"  }
    ]
   dns = {
      servers = ["192.168.100.7"]
      search  = "local"
    }

  }
}

}
)






