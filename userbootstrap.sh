#!/bin/bash

##############################################################################
# Proxmox User Bootstrap Script
#
# This script creates a terraform user with Proxmox API access for automation.
# It creates a local Linux user, Proxmox user, custom role with VM/disk permissions,
# and generates an API token.
#
# Usage: ./userbootstrap.sh
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
API_USER="terraform"
API_USER_REALM="pam"
API_USER_COMMENT="Terraform Infrastructure User"
ROLE_NAME="APIAutomation"
ROLE_COMMENT="API Automation Group - VM and Disk Management"
TOKEN_NAME="terraform-token"
TOKEN_COMMENT="Token for Terraform infrastructure management"

##############################################################################
# Helper Functions
##############################################################################

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Collect interactive input
collect_input() {
    echo -e "${BLUE}Proxmox Host Setup${NC}"
    echo "This script will create a terraform user with Proxmox API access."
    echo "It will create a local Linux user, Proxmox user, and API token."
    echo ""

    # Prompt for Proxmox hostname
    read -p "Enter Proxmox hostname or IP address: " PROXMOX_HOST
    while [[ -z "$PROXMOX_HOST" ]]; do
        echo -e "${RED}Hostname cannot be empty.${NC}"
        read -p "Enter Proxmox hostname or IP address: " PROXMOX_HOST
    done

    # Prompt for root password
    echo ""
    echo -e "${YELLOW}SSH Authentication${NC}"
    echo "Connecting as root user to $PROXMOX_HOST:"
    read -s -p "Root password: " ROOT_PASSWORD
    echo ""
    while [[ -z "$ROOT_PASSWORD" ]]; do
        echo -e "${RED}Password cannot be empty.${NC}"
        read -s -p "Root password: " ROOT_PASSWORD
        echo ""
    done

    # Prompt for terraform user password
    echo ""
    echo -e "${YELLOW}Terraform User Setup${NC}"
    echo "Creating local Linux user '$API_USER' for Terraform operations."
    read -s -p "Password for $API_USER user: " USER_PASSWORD
    echo ""
    while [[ -z "$USER_PASSWORD" ]]; do
        echo -e "${RED}Password cannot be empty.${NC}"
        read -s -p "Password for $API_USER user: " USER_PASSWORD
        echo ""
    done

    # Confirm password
    read -s -p "Confirm password for $API_USER user: " USER_PASSWORD_CONFIRM
    echo ""
    while [[ "$USER_PASSWORD" != "$USER_PASSWORD_CONFIRM" ]]; do
        echo -e "${RED}Passwords do not match. Please try again.${NC}"
        read -s -p "Password for $API_USER user: " USER_PASSWORD
        echo ""
        read -s -p "Confirm password for $API_USER user: " USER_PASSWORD_CONFIRM
        echo ""
    done
}

# Test SSH connection and pvesh availability
test_connection() {
    print_info "Testing SSH connection to $PROXMOX_HOST..."

    if ! sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "which pvesh" &>/dev/null; then
        print_error "Cannot connect to Proxmox host or pvesh not available"
        print_info "Make sure:"
        print_info "  - SSH credentials are correct"
        print_info "  - Proxmox host is reachable"
        print_info "  - Root SSH access is enabled"
        exit 1
    fi

    print_success "SSH connection and pvesh availability confirmed"
}

# Create local Linux user
create_local_user() {
    print_info "Creating local Linux user: $API_USER..."

    # Create the user with home directory and bash shell
    if ! sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "useradd -m -s /bin/bash $API_USER" 2>/dev/null; then
        print_warning "Local user $API_USER might already exist. Continuing..."
    else
        print_success "Local user $API_USER created"
    fi

    # Set the password for the user
    print_info "Setting password for user $API_USER..."
    if ! sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "echo '$API_USER:$USER_PASSWORD' | chpasswd" 2>/dev/null; then
        print_error "Failed to set password for user $API_USER"
        exit 1
    fi

    print_success "Password set for user $API_USER"
}

# Create Proxmox user
create_proxmox_user() {
    print_info "Creating Proxmox user: $API_USER@$API_USER_REALM..."

    if ! sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pveum user add $API_USER@$API_USER_REALM --comment '$API_USER_COMMENT' --enable 1" 2>/dev/null; then
        print_warning "Proxmox user $API_USER@$API_USER_REALM might already exist. Continuing..."
    else
        print_success "Proxmox user $API_USER@$API_USER_REALM created"
    fi
}

# Create API Automation role with VM and disk permissions
create_automation_role() {
    print_info "Creating API Automation role: $ROLE_NAME..."

    # Create the role with permissions for VM and storage operations
    # VM permissions: Allocate, Config, Monitor, PowerMgmt, Console
    # Storage permissions: AllocateSpace, Allocate
    if ! sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pveum role add $ROLE_NAME --comment '$ROLE_COMMENT'" 2>/dev/null; then
        print_warning "Role $ROLE_NAME might already exist. Continuing..."
    else
        print_success "Role $ROLE_NAME created"
    fi

    # Add VM permissions to the role
    sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pveum role modify $ROLE_NAME --privs VM.Allocate,VM.Config.CPU,VM.Config.Memory,VM.Config.Disk,VM.Config.Network,VM.Config.HWType,VM.Monitor,VM.PowerMgmt,VM.Console,Datastore.AllocateSpace,Datastore.Allocate" 2>/dev/null || true

    print_success "VM and storage permissions added to role $ROLE_NAME"
}

# Set user permissions with the automation role
set_user_permissions() {
    print_info "Setting $ROLE_NAME permissions for $API_USER@$API_USER_REALM..."

    # Grant the role to the user on /vms and /storage paths
    sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pveum acl modify /vms --roles $ROLE_NAME --users $API_USER@$API_USER_REALM" 2>/dev/null || true
    sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pveum acl modify /storage --roles $ROLE_NAME --users $API_USER@$API_USER_REALM" 2>/dev/null || true

    print_success "$ROLE_NAME permissions set for $API_USER@$API_USER_REALM"
}

# Generate API token
generate_api_token() {
    print_info "Generating API token for $API_USER..."

    # Check if token already exists and delete it
    print_info "Checking for existing token..."
    sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pvesh delete /access/users/$API_USER@$API_USER_REALM/token/$TOKEN_NAME" 2>/dev/null || true

    local token_output
    if ! token_output=$(sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$PROXMOX_HOST "pvesh create /access/users/$API_USER@$API_USER_REALM/token/$TOKEN_NAME --comment '$TOKEN_COMMENT' --privsep 0" 2>&1); then
        print_error "Failed to generate API token"
        print_info "Error output: $token_output"
        print_info "Make sure the Proxmox user was created successfully"
        exit 1
    fi

    # Extract token value from JSON output
    local token_value=$(echo "$token_output" | grep -o '"value":"[^"]*"' | cut -d'"' -f4)

    if [[ -z "$token_value" ]]; then
        print_error "Failed to extract token value from response"
        print_info "Raw response: $token_output"
        exit 1
    fi

    print_success "API token generated successfully"

    # Display token information
    print_header "API Token Generated"
    echo -e "${GREEN}User ID:${NC} $API_USER@$API_USER_REALM"
    echo -e "${GREEN}Token ID:${NC} $TOKEN_NAME"
    echo -e "${GREEN}Token Secret:${NC} $token_value"
    echo ""
    echo -e "${YELLOW}Add this to your terraform.tfvars file:${NC}"
    echo "proxmox_api_token_id = \"$API_USER@$API_USER_REALM!$TOKEN_NAME\""
    echo "proxmox_api_token    = \"$token_value\""
    echo ""
    echo -e "${RED}⚠ IMPORTANT: Save this token securely! It will not be shown again.${NC}"
}

##############################################################################
# Main Script
##############################################################################

main() {
    print_header "Proxmox User Bootstrap Script"

    # Collect interactive input
    collect_input

    echo "Configuration:"
    echo "  Proxmox Host: $PROXMOX_HOST"
    echo "  API User: $API_USER@$API_USER_REALM"
    echo "  Role: $ROLE_NAME"
    echo ""

    # Test connection
    test_connection

    # Create local Linux user
    create_local_user

    # Create Proxmox user
    create_proxmox_user

    # Create automation role
    create_automation_role

    # Set user permissions
    set_user_permissions

    # Generate API token
    generate_api_token

    print_header "Bootstrap Complete"
    print_success "Terraform user and API token created successfully!"
    print_info "The user has permissions to create VMs and manage disks via the API."
}

# Run main function
main "$@"