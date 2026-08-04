resource "proxmox_virtual_environment_file" "cloud_init" {
  content_type = "snippets"
  datastore_id = var.storage_hdd
  node_name    = var.proxmox_node

  source_raw {
    data = <<-EOT
	#cloud-config
	hostname: ${var.vm_name}
	manage_etc_hosts: true

	# Пользователи создаются через user_account в Proxmox, здесь их дублировать не нужно.
	users:
	  - default
	  - name: ${var.ansible_user}
	    primary_group: Administrators
	    groups: sudo
	    shell: /bin/bash
	    sudo: ALL=(ALL) NOPASSWD:ALL
	    ssh_authorized_keys:
	      - ${var.ansible_ssh_public_key}

	package_update: false
	package_upgrade: false
	EOT
    file_name = "cloud-init-${var.vm_name}.yml"

  }
}
