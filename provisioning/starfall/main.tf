resource "incus_instance" "starfall" {
  for_each    = var.vms
  name        = each.key
  description = "Managed by Terraform"
  type        = "virtual-machine"
  image       = var.vm_image
  config = {
    "limits.cpu"     = each.value.cpu
    "limits.memory"  = each.value.memory
    "boot.autostart" = "false"
    "cloud-init.user-data" = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
      vm_name       = each.key
      timezone      = var.timezone
      root_password = var.root_password
    })
    "user.managed-by" = "terraform"
  }
  device {
    name = "root"
    type = "disk"
    properties = {
      pool = var.storage_pool
      path = "/"
      size = each.value.disk_size
    }
  }
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network        = var.network
      "ipv4.address" = each.value.ipv4_address
    }
  }
  device {
    name = "agent"
    type = "disk"
    properties = {
      source = "agent:config"
      path   = "/dev/incus"
    }
  }
  wait_for {
    type = "agent"
  }
  lifecycle {
    ignore_changes = [running]
  }
}

resource "null_resource" "cloud_init_wait" {
  for_each = incus_instance.starfall
  triggers = {
    instance_name = each.value.name
    mac_address   = each.value.mac_address
  }
  provisioner "local-exec" {
    command = "incus exec ${each.value.name} -- cloud-init status --wait --long"
  }
}
