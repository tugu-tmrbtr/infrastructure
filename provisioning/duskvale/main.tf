terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "1.2.0"
    }
  }
}

provider "incus" {}

resource "incus_instance" "duskvale" {
  name  = "duskvale"
  type  = "virtual-machine"
  image = "images:almalinux/10"

  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "8GiB"
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      pool = "default"
      path = "/"
      size = "48GiB"
    }
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      network = "incusbr0"
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
}
