# Proxmox Terraform Stack

This Terraform configuration provisions multiple VMs on Proxmox using the Telmate provider.

## Prerequisites

1. **Terraform** >= 1.0 installed
2. **Proxmox** cluster with API access enabled
3. **API Token** created in Proxmox with appropriate permissions
4. **VM Template** already created in Proxmox to clone from

## Setup Instructions

### 1. Create Proxmox API Token

1. Log into Proxmox Web UI
2. Navigate to **Datacenter** → **Permissions** → **API Tokens**
3. Click **Add** to create a new token
4. Set the following:
   - **User**: `terraform` (or your user)
   - **Realm**: `pam`
   - **Token ID**: `terraform-token`
   - **Privilege Separation**: Enabled (optional)
5. Copy the token secret immediately (shown only once)

### 2. Grant Permissions

In Proxmox, grant the API token permissions:
- **Path**: `/nodes`
- **Permission**: `Sys.Audit`, `Vm.Allocate`, `Vm.Clone`, `Vm.Config.All`, `Vm.Monitor`, `Vm.PowerMgmt`

### 3. Configure Terraform

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your Proxmox details:
   ```hcl
   proxmox_api_url      = "https://YOUR_PROXMOX_IP:8006/api2/json"
   proxmox_api_token_id = "terraform@pam!terraform-token"
   proxmox_api_token    = "YOUR_TOKEN_SECRET"
   proxmox_tls_insecure = false  # Set to true only if using self-signed certs in dev
   ```

3. (Optional) Override VM configuration in `terraform.tfvars` - the stack includes default VMs

### 4. Create VM Template (if not exists)

You need a template to clone from. Example:
- Ubuntu 22.04 template named `ubuntu-22-04-template`

### 5. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply
```

## Configuration

### Default VMs

The stack creates 3 default VMs:
- **web-server-1**: 2 vCPU, 2GB RAM, VMID 100
- **web-server-2**: 2 vCPU, 2GB RAM, VMID 101
- **database-server**: 4 vCPU, 4GB RAM, VMID 102

All nodes default to `pve-node-1` and `pve-node-2`. Modify in `terraform.tfvars`.

### Customizing VMs

Edit `terraform.tfvars` to add/modify VMs:

```hcl
vms = {
  "my-custom-vm" = {
    name               = "my-custom-vm"
    vmid               = 200
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
}
```

### Adding Multiple Disks

```hcl
disks = [
  {
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
    format  = "raw"
  },
  {
    type    = "scsi"
    storage = "local-lvm"
    size    = "50G"
    format  = "raw"
  }
]
```

### Adding Multiple Network Interfaces

```hcl
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
```

## Cloud-Init Configuration

The stack supports cloud-init for VM initialization. Edit `cloud-init.yaml` to customize:
- Hostname/FQDN
- Users and SSH keys
- Packages to install
- Custom scripts

To enable cloud-init for a VM, set `cloud_init_enabled = true`.

## Common Operations

### View Created Resources

```bash
terraform show
```

### View State

```bash
terraform state list
```

### Destroy Infrastructure

```bash
terraform destroy
```

### Destroy Specific VM

```bash
terraform destroy -target='proxmox_vm_qemu.vm["web-server-1"]'
```

### Add New VM

1. Add to `terraform.tfvars`
2. Run `terraform apply`

### Modify Existing VM

1. Update configuration in `terraform.tfvars`
2. Run `terraform apply`

Note: Some changes may require VM restart

## File Structure

```
.
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── terraform.tfvars.example     # Example values (copy and customize)
├── cloud-init.yaml              # Cloud-init template
├── terraform.tfstate            # State file (auto-generated)
├── terraform.tfstate.backup     # State backup (auto-generated)
└── README.md                    # This file
```

## Troubleshooting

### Authentication Error
- Verify API token and URL in `terraform.tfvars`
- Check token permissions in Proxmox
- Ensure user has required roles

### Template Not Found
- Verify template name in `terraform.tfvars`
- Check template exists in Proxmox Web UI
- Ensure template is on correct nodes

### VMID Already Exists
- Choose unique VMID for each VM (100-9999)
- Check existing VMs in Proxmox

### Network Issues
- Verify bridge names (vmbr0, vmbr1, etc.)
- Check network configuration in Proxmox
- Ensure VMs have correct network settings

### Cloud-Init Not Running
- Enable Qemu Guest Agent on template
- Check cloud-init logs: `cloud-init status`
- Verify cloud_init_enabled is set to true

## Security Notes

1. **Never commit** `terraform.tfvars` with secrets to version control
2. Add `terraform.tfvars` to `.gitignore`
3. Use environment variables for sensitive data:
   ```bash
   export TF_VAR_proxmox_api_token="your-secret"
   ```
4. Set `proxmox_tls_insecure = false` in production
5. Regularly rotate API tokens

## Additional Resources

- [Telmate Proxmox Provider](https://github.com/Telmate/terraform-provider-proxmox)
- [Proxmox API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Cloud-Init Documentation](https://cloud-init.io/)

## License

This configuration is provided as-is for infrastructure provisioning.
