locals {
  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    vm_name       = var.vm_name
    timezone      = var.timezone
    root_password = var.root_password
  })
}

resource "incus_instance" "duskvale" {
  name        = var.vm_name
  description = "Managed by Terraform"
  type        = "virtual-machine"
  image       = var.vm_image

  config = {
    "limits.cpu"    = var.vm_cpu
    "limits.memory" = var.vm_memory
    "boot.autostart" = "false"
    "cloud-init.user-data" = local.user_data
    "user.managed-by"      = "terraform"
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      pool = var.storage_pool
      path = "/"
      size = var.disk_size
    }
  }

  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = var.network
      "ipv4.address" = var.ipv4_address
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
