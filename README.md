# Proxmox Terraform Stack

This Terraform configuration provisions multiple VMs on Proxmox using the Telmate provider.

## Quick Start

```bash
# 1. Bootstrap your host (first time only)
sudo ./bootstraphost.sh

# 2. Bootstrap Proxmox API user (first time only)
./userbootstrap.sh

# 3. Configure your Proxmox credentials
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# 4. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 5. View created resources
make output

# 6. Destroy when done
terraform destroy
```

For detailed instructions, see [Setup Instructions](#setup-instructions) below.

## Prerequisites

1. **Linux Host** - Debian/Ubuntu or Fedora/RHEL/CentOS
2. **Sudo or Root Access** - Required to install packages
3. **Proxmox** cluster with API access enabled
4. **API Token** created in Proxmox with appropriate permissions
5. **VM Template** already created in Proxmox to clone from

## Setup Instructions

### 1. Bootstrap Your Host (First Time Only)

Before using Terraform, you must install required packages on your Linux host.

**For Debian/Ubuntu or Fedora/RHEL:**

```bash
# Clone or download this repository
cd bootstrap

# Run the bootstrap script (requires sudo or root)
sudo ./bootstraphost.sh
```

The bootstrap script will:
- ✓ Detect your Linux distribution (Debian/Ubuntu or Fedora/RHEL)
- ✓ Update your package manager
- ✓ Install Terraform
- ✓ Install required dependencies (curl, git, jq, openssh-client, ca-certificates, sshpass)
- ✓ Install optional tools (make, vim, tflint)
- ✓ Verify all installations

**Expected Output:**
```
========================================
Proxmox Terraform Bootstrap Script
========================================

✓ Detected Debian/Ubuntu (ubuntu 22.04)
✓ Package manager updated
✓ Core dependencies installed
✓ Terraform installed
✓ Optional tools installation complete
✓ terraform: Terraform v1.x.x...
✓ curl: curl 7.x.x...
✓ git: git version 2.x.x...
...
✓ Bootstrap complete!
```

### 2. Bootstrap Proxmox API User (First Time Only)

Before running Terraform, you need to create an API user on your Proxmox host with appropriate permissions for VM and disk management.

**Run the user bootstrap script:**

```bash
# Interactive mode (recommended) - will prompt for hostname and password
./userbootstrap.sh
```

The script will:
- ✓ **Prompt for Proxmox hostname** and root password
- ✓ **Prompt for Terraform user password** (with confirmation)
- ✓ Connect to your Proxmox host via SSH
- ✓ Create a local Linux user called `terraform` with home directory and bash shell
- ✓ Set the password for the `terraform` user
- ✓ Create the Proxmox user `terraform@pam`
- ✓ Create "APIAutomation" role with VM and storage permissions
- ✓ Assign the role to the user on `/vms` and `/storage` paths
- ✓ Generate an API token
- ✓ Display the token for use in `terraform.tfvars`

**Interactive Prompts:**
```
Proxmox Host Setup
This script will create a terraform user with Proxmox API access.
It will create a local Linux user, Proxmox user, and API token.

Enter Proxmox hostname or IP address: proxmox.example.com

SSH Authentication
Connecting as root user to proxmox.example.com:
Root password: [hidden input]

Terraform User Setup
Creating local Linux user 'terraform' for Terraform operations.
Password for terraform user: [hidden input]
Confirm password for terraform user: [hidden input]
```

**Expected Output:**
```
========================================
Proxmox User Bootstrap Script
========================================

✓ SSH connection and pvesh availability confirmed
✓ Local user terraform created
✓ Password set for user terraform
✓ Proxmox user terraform@pam created
✓ Role APIAutomation created
✓ VM and storage permissions added to role APIAutomation
✓ APIAutomation permissions set for terraform@pam
✓ API token generated successfully

========================================
API Token Generated
========================================
User ID: terraform@pam
Token ID: terraform-token
Token Secret: your-generated-token-here

Add this to your terraform.tfvars file:
proxmox_api_token_id = "terraform@pam!terraform-token"
proxmox_api_token    = "your-generated-token-here"

⚠ IMPORTANT: Save this token securely! It will not be shown again.
```

**Permissions Granted:**
The `terraform@pam` user gets the "APIAutomation" role with permissions for:
- **VM Operations**: Allocate, Configure (CPU/Memory/Disk/Network), Monitor, Power Management, Console
- **Storage Operations**: Allocate Space, Allocate
- **Paths**: `/vms` and `/storage` (full access to create/manage VMs and disks)

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
├── bootstraphost.sh             # Bootstrap script (install dependencies including sshpass)
├── userbootstrap.sh             # Create Proxmox API user and token
├── main.tf                      # Main Terraform configuration
├── variables.tf                 # Variable definitions
├── outputs.tf                   # Output value definitions
├── locals.tf                    # Local variable definitions
├── terraform.tfvars.example     # Example values (copy and customize)
├── cloud-init.yaml              # Cloud-init template
├── examples.md                  # Example VM configurations
├── Makefile                     # Convenient make commands
├── .gitignore                   # Git ignore patterns
├── terraform.tfstate            # State file (auto-generated)
├── terraform.tfstate.backup     # State backup (auto-generated)
└── README.md                    # This file
```

### File Descriptions

| File | Purpose |
|------|---------|
| `bootstraphost.sh` | Automated setup script - installs Terraform and dependencies (including sshpass) on Debian/Ubuntu or Fedora/RHEL |
| `userbootstrap.sh` | Interactive script to create Proxmox API user with VM/disk permissions and generate API token |
| `main.tf` | Core Terraform configuration with Proxmox provider and VM resources |
| `variables.tf` | Input variables with types, defaults, and descriptions |
| `outputs.tf` | Output values exported after deployment |
| `locals.tf` | Local values for common configuration |
| `terraform.tfvars.example` | Template for sensitive values (copy to `terraform.tfvars`) |
| `cloud-init.yaml` | Cloud-init configuration template for VM initialization |
| `examples.md` | Various VM configuration examples for different use cases |
| `Makefile` | Convenience commands: `make init`, `make plan`, `make apply`, etc. |
| `.gitignore` | Prevents committing sensitive files and artifacts |

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
