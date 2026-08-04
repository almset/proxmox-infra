variable "proxmox_api_url" {
  type        = string
  description = "Proxmox API endpoint"
}

variable "proxmox_username" {
  type        = string
  description = "Proxmox username"
}

variable "proxmox_password" {
  type        = string
  description = "Proxmox password"
  sensitive   = true
}

variable "proxmox_node" {
  type        = string
  description = "Proxmox node name"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "production"
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Must be: production, staging, or development"
  }
}

#variable "template_vm_id" {
#  type        = number
#  description = "Base template VM ID"
#  default     = 9991
#}
#
variable "template" {
  description = "Base template VM ID"
  default     = "ubuntu-22"
}


variable "ansible_user" {
  type        = string
  description = "Ansible username"
  default     = "ansible"
}

variable "ansible_ssh_public_key" {
  description = "Path to public Ansible SSH key"
  type        = string
  default     = "ansible_key.pub"
}

variable "storage_ssd" {
  type        = string
  description = "SSD storage"
  default     = "local-ssd-seagate2tb"
}

variable "storage_hdd" {
  type        = string
  description = "HDD storage for cloud-init"
  default     = "local-hdd-wd2tb"
}

variable "vm_configs" {
  type = map(object({
    vm_id    = number
    platform   = string
    role       = string
    cores    = number
    memory   = number
    disk     = number
    networks = list(object({
      bridge  = string
      ip      = string
      gateway = optional(string)
    }))
    extra_disk = optional(number)
    
    dns = optional(object({
        servers = list(string)
        search  = string
    }))

  }))
  description = "VM configurations"
}

