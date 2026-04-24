terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
  required_version = ">= 1.0"
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token    = var.proxmox_api_token
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Create multiple VMs
resource "proxmox_vm_qemu" "vm" {
  for_each = var.vms

  name        = each.value.name
  target_node = each.value.target_node
  vmid        = each.value.vmid
  clone       = each.value.clone_template

  # CPU and Memory
  cores   = each.value.cores
  sockets = 1
  memory  = each.value.memory
  balloon = each.value.balloon

  # Boot settings
  boot = each.value.boot_order

  # Network configuration
  dynamic "network" {
    for_each = each.value.networks
    content {
      model  = network.value.model
      bridge = network.value.bridge
    }
  }

  # Disk configuration
  dynamic "disk" {
    for_each = each.value.disks
    content {
      type    = disk.value.type
      storage = disk.value.storage
      size    = disk.value.size
      format  = disk.value.format
    }
  }

  # Cloud-init configuration (if needed)
  dynamic "cloud_init_custom_config" {
    for_each = each.value.cloud_init_enabled ? [1] : []
    content {
      custom_configuration = templatefile("${path.module}/cloud-init.yaml", {
        hostname = each.value.name
        username = each.value.cloud_init_user
      })
    }
  }

  # Enable agent
  agent           = each.value.agent_enabled
  hotplug         = each.value.hotplug_enabled
  onboot          = each.value.on_boot
  automatic_reboot = false
  full_clone      = each.value.full_clone

  # Lifecycle settings
  lifecycle {
    ignore_changes = [
      network,
    ]
  }

  depends_on = []
}

# Output VM information
output "vm_details" {
  description = "Details of created VMs"
  value = {
    for name, vm in proxmox_vm_qemu.vm : name => {
      vmid = vm.vmid
      name = vm.name
      node = vm.target_node
    }
  }
}
