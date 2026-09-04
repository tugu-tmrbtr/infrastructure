variable "vm_name" {
  description = "Incus VM name"
  type        = string
  default     = "duskvale"
}

variable "vm_image" {
  description = "Incus image (cloud variant — cloud-init required)"
  type        = string
  default     = "images:almalinux/10/cloud"
}

variable "vm_cpu" {
  description = "Number of vCPUs"
  type        = string
  default     = "2"
}

variable "vm_memory" {
  description = "VM memory"
  type        = string
  default     = "8GiB"
}

variable "disk_size" {
  description = "Root disk size"
  type        = string
  default     = "48GiB"
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

variable "ipv4_address" {
  description = "Static IP on the managed bridge (outside DHCP range)"
  type        = string
  default     = "10.10.10.30"
}

variable "root_password" {
  description = "Plain-text root password"
  type        = string
  sensitive   = true
  default     = "Password2@"
}
