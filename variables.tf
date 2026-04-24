variable "proxmox_api_url" {
  description = "Proxmox API URL (e.g., https://10.0.0.1:8006/api2/json)"
  type        = string
  sensitive   = false
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID (format: user@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification for Proxmox API (not recommended for production)"
  type        = bool
  default     = false
}

variable "vms" {
  description = "Map of VMs to create"
  type = map(object({
    name               = string
    vmid               = number
    target_node        = string
    clone_template     = string
    cores              = number
    memory             = number
    balloon            = number
    boot_order         = string
    on_boot            = bool
    full_clone         = bool
    agent_enabled      = bool
    hotplug_enabled    = string
    cloud_init_enabled = bool
    cloud_init_user    = string

    networks = list(object({
      model  = string
      bridge = string
    }))

    disks = list(object({
      type    = string
      storage = string
      size    = string
      format  = string
    }))
  }))

  default = {
    "web-server-1" = {
      name               = "web-server-1"
      vmid               = 100
      target_node        = "pve-node-1"
      clone_template     = "ubuntu-22-04-template"
      cores              = 2
      memory             = 2048
      balloon            = 1024
      boot_order         = "order=scsi0;ide2;net0"
      on_boot            = true
      full_clone         = true
      agent_enabled      = true
      hotplug_enabled    = "network,disk,cpu,memory"
      cloud_init_enabled = true
      cloud_init_user    = "ubuntu"

      networks = [
        {
          model  = "virtio"
          bridge = "vmbr0"
        }
      ]

      disks = [
        {
          type    = "scsi"
          storage = "local-lvm"
          size    = "20G"
          format  = "raw"
        }
      ]
    }

    "web-server-2" = {
      name               = "web-server-2"
      vmid               = 101
      target_node        = "pve-node-1"
      clone_template     = "ubuntu-22-04-template"
      cores              = 2
      memory             = 2048
      balloon            = 1024
      boot_order         = "order=scsi0;ide2;net0"
      on_boot            = true
      full_clone         = true
      agent_enabled      = true
      hotplug_enabled    = "network,disk,cpu,memory"
      cloud_init_enabled = true
      cloud_init_user    = "ubuntu"

      networks = [
        {
          model  = "virtio"
          bridge = "vmbr0"
        }
      ]

      disks = [
        {
          type    = "scsi"
          storage = "local-lvm"
          size    = "20G"
          format  = "raw"
        }
      ]
    }

    "database-server" = {
      name               = "database-server"
      vmid               = 102
      target_node        = "pve-node-2"
      clone_template     = "ubuntu-22-04-template"
      cores              = 4
      memory             = 4096
      balloon            = 2048
      boot_order         = "order=scsi0;ide2;net0"
      on_boot            = true
      full_clone         = true
      agent_enabled      = true
      hotplug_enabled    = "network,disk,cpu,memory"
      cloud_init_enabled = true
      cloud_init_user    = "ubuntu"

      networks = [
        {
          model  = "virtio"
          bridge = "vmbr0"
        }
      ]

      disks = [
        {
          type    = "scsi"
          storage = "local-lvm"
          size    = "50G"
          format  = "raw"
        }
      ]
    }
  }
}
