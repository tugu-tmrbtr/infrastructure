output "vms" {
  description = "VM name, status and IP"
  value = {
    for name, vm in incus_instance.starfall : name => {
      status = vm.status
      ipv4   = var.vms[name].ipv4_address
    }
  }
}
output "ssh_commands" {
  description = "SSH commands (cloud-init complete)"
  value = {
    for name, cfg in var.vms : name => "ssh root@${cfg.ipv4_address}"
  }
  depends_on = [null_resource.cloud_init_wait]
}
