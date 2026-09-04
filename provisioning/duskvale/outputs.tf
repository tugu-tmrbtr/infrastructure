output "vm_name" {
  description = "Created VM name"
  value       = incus_instance.duskvale.name
}

output "vm_status" {
  description = "VM status"
  value       = incus_instance.duskvale.status
}

output "ipv4_address" {
  description = "VM IPv4 address"
  value       = var.ipv4_address
}

output "ssh_command" {
  description = "SSH command"
  value       = "ssh root@${var.ipv4_address}"
}
