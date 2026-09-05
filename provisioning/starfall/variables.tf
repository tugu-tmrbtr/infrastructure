variable "vms" {
  description = "VM definitions keyed by name"
  type = map(object({
    ipv4_address = string
    cpu          = optional(string, "2")
    memory       = optional(string, "4GiB")
    disk_size    = optional(string, "48GiB")
  }))

  default = {
    starfall-01 = { ipv4_address = "10.10.10.41" }
    starfall-02 = { ipv4_address = "10.10.10.42" }
    starfall-03 = { ipv4_address = "10.10.10.43" }
  }
}

variable "vm_image" {
  description = "Incus image (cloud variant — cloud-init required)"
  type        = string
  default     = "images:almalinux/10/cloud"
}

variable "storage_pool" {
  description = "Incus storage pool"
  type        = string
  default     = "default"
}

variable "network" {
  description = "Incus managed network"
  type        = string
  default     = "incusbr0"
}

variable "timezone" {
  description = "Guest timezone"
  type        = string
  default     = "Asia/Ulaanbaatar"
}

variable "root_password" {
  description = "Plain-text root password"
  type        = string
  sensitive   = true
  default     = "Password2@"
}
