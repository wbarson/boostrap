locals {
  # Common tags for all resources
  common_tags = {
    managed_by = "terraform"
    project    = "infrastructure"
    created_at = timestamp()
  }

  # Default boot order
  default_boot_order = "order=scsi0;ide2;net0"

  # Default hotplug features
  default_hotplug = "network,disk,cpu,memory"

  # Common network model
  default_network_model = "virtio"
}
