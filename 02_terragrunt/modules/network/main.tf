# resource "proxmox_virtual_environment_network_linux_bridge" "bridge" {
#   for_each = var.bridges
#   node_name = var.proxmox_node
#   name      = each.value.name
# }

output "network_map" {
  value = var.bridges
}
