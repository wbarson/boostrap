# Proxmox Terraform - Configuration Examples

This file contains various example configurations for different VM types and use cases.

## Lightweight Web Server

```hcl
"lightweight-web" = {
  name               = "lightweight-web"
  vmid               = 200
  target_node        = "pve-node-1"
  clone_template     = "ubuntu-22-04-template"
  cores              = 1
  memory             = 512
  balloon            = 256
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
      size    = "10G"
      format  = "raw"
    }
  ]
}
```

## High-Performance Database Server

```hcl
"high-performance-db" = {
  name               = "high-performance-db"
  vmid               = 201
  target_node        = "pve-node-2"
  clone_template     = "ubuntu-22-04-template"
  cores              = 8
  memory             = 16384
  balloon            = 8192
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
    },
    {
      model  = "virtio"
      bridge = "vmbr1"
    }
  ]

  disks = [
    {
      type    = "scsi"
      storage = "local-lvm"
      size    = "100G"
      format  = "raw"
    },
    {
      type    = "scsi"
      storage = "local-lvm"
      size    = "200G"
      format  = "raw"
    }
  ]
}
```

## Development/Testing VM

```hcl
"dev-vm" = {
  name               = "dev-vm"
  vmid               = 202
  target_node        = "pve-node-1"
  clone_template     = "ubuntu-22-04-template"
  cores              = 4
  memory             = 4096
  balloon            = 2048
  boot_order         = "order=scsi0;ide2;net0"
  on_boot            = false
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
      size    = "30G"
      format  = "raw"
    }
  ]
}
```

## Application Server with Multiple Disks

```hcl
"app-server" = {
  name               = "app-server"
  vmid               = 203
  target_node        = "pve-node-1"
  clone_template     = "ubuntu-22-04-template"
  cores              = 4
  memory             = 8192
  balloon            = 4096
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
      size    = "30G"
      format  = "raw"
    },
    {
      type    = "scsi"
      storage = "local-lvm"
      size    = "100G"
      format  = "raw"
    }
  ]
}
```

## High-Availability Cluster Node

```hcl
"cluster-node-1" = {
  name               = "cluster-node-1"
  vmid               = 204
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
    },
    {
      model  = "virtio"
      bridge = "vmbr1"
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

"cluster-node-2" = {
  name               = "cluster-node-2"
  vmid               = 205
  target_node        = "pve-node-2"
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
    },
    {
      model  = "virtio"
      bridge = "vmbr1"
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
```

## Kubernetes Control Plane Node

```hcl
"k8s-control" = {
  name               = "k8s-control"
  vmid               = 210
  target_node        = "pve-node-1"
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
```

## Kubernetes Worker Node

```hcl
"k8s-worker-1" = {
  name               = "k8s-worker-1"
  vmid               = 220
  target_node        = "pve-node-1"
  clone_template     = "ubuntu-22-04-template"
  cores              = 4
  memory             = 8192
  balloon            = 4096
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
```

## Minimal VM (Testing/Demo)

```hcl
"minimal-vm" = {
  name               = "minimal-vm"
  vmid               = 250
  target_node        = "pve-node-1"
  clone_template     = "ubuntu-22-04-template"
  cores              = 1
  memory             = 1024
  balloon            = 512
  boot_order         = "order=scsi0;ide2;net0"
  on_boot            = false
  full_clone         = false
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
      size    = "8G"
      format  = "raw"
    }
  ]
}
```

## Usage

1. Copy any of these configurations into your `terraform.tfvars` file
2. Adjust the VMID to be unique
3. Update node names if necessary
4. Run `terraform plan` to review changes
5. Run `terraform apply` to create the VMs

## Tips

- **VMID Range**: Use 100-199 for web servers, 200-299 for application servers, 300-399 for databases
- **Memory Allocation**: Always set balloon to half of memory for better performance
- **Storage**: Adjust storage names based on your Proxmox configuration (local-lvm, local, proxmox-data, etc.)
- **Networking**: Verify bridge names match your Proxmox network configuration
- **Node Distribution**: Spread VMs across multiple nodes for load balancing
