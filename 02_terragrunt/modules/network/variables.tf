variable "proxmox_node" { type = string }
variable "bridges" {
  type = map(object({
    name       = string
    cidr       = optional(string)
    gateway    = optional(string)
    vlan_aware = optional(bool)
  }))
  default = {}
}
