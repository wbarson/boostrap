#!/bin/bash

##############################################################################
# Bootstrap Script for Proxmox Terraform Stack
# 
# This script installs all required packages needed to run the Terraform
# configuration for provisioning VMs on Proxmox.
#
# Supports: Debian/Ubuntu and Fedora/RHEL/CentOS
#
# Usage: ./bootstraphost.sh
##############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_VERSION="latest"
INSTALL_OPTIONAL=true

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

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root (or with sudo)"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS=$(echo $DISTRIB_ID | tr '[:upper:]' '[:lower:]')
        VERSION=$DISTRIB_RELEASE
    elif [[ -f /etc/redhat-release ]]; then
        OS=$(cat /etc/redhat-release | awk '{print tolower($1)}')
        VERSION=$(cat /etc/redhat-release | grep -oP '(?<=release )[^ ]*' | head -1)
    else
        print_error "Cannot detect Linux distribution"
        exit 1
    fi

    case $OS in
        ubuntu|debian)
            DISTRO_TYPE="debian"
            print_success "Detected Debian/Ubuntu ($OS $VERSION)"
            ;;
        fedora|centos|rhel|rocky|almalinux)
            DISTRO_TYPE="fedora"
            print_success "Detected Fedora/RHEL ($OS $VERSION)"
            ;;
        *)
            print_error "Unsupported distribution: $OS"
            exit 1
            ;;
    esac
}

# Update package manager
update_package_manager() {
    print_info "Updating package manager..."
    if [[ $DISTRO_TYPE == "debian" ]]; then
        apt-get update -qq
    else
        dnf check-update -q || true
    fi
    print_success "Package manager updated"
}

# Install required packages for Debian/Ubuntu
install_debian_packages() {
    print_header "Installing packages for Debian/Ubuntu"
    
    local packages="curl wget git jq unzip openssh-client ca-certificates"
    
    print_info "Installing core dependencies: $packages"
    apt-get install -y -qq $packages
    print_success "Core dependencies installed"
}

# Install Terraform on Debian/Ubuntu
install_terraform_debian() {
    print_info "Installing Terraform..."
    
    # Add HashiCorp GPG key
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - > /dev/null 2>&1
    
    # Add HashiCorp repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
    
    # Update and install
    apt-get update -qq
    apt-get install -y -qq terraform
    
    print_success "Terraform installed"
}

# Install required packages for Fedora/RHEL
install_fedora_packages() {
    print_header "Installing packages for Fedora/RHEL"
    
    local packages="curl wget git jq unzip openssh-clients ca-certificates"
    
    print_info "Installing core dependencies: $packages"
    dnf install -y -q $packages
    print_success "Core dependencies installed"
}

# Install Terraform on Fedora/RHEL
install_terraform_fedora() {
    print_info "Installing Terraform..."
    
    # Add HashiCorp repository
    dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo > /dev/null 2>&1
    
    # Install
    dnf install -y -q terraform
    
    print_success "Terraform installed"
}

# Install optional tools
install_optional_tools() {
    print_header "Installing Optional Tools"
    
    if [[ $DISTRO_TYPE == "debian" ]]; then
        print_info "Installing optional packages for Debian/Ubuntu..."
        apt-get install -y -qq make vim git-extras || print_warning "Some optional packages failed to install"
        
        # Install tflint (optional linter)
        if command -v curl &> /dev/null; then
            print_info "Installing tflint (Terraform linter)..."
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh 2>/dev/null | bash || \
                print_warning "Failed to install tflint"
        fi
    else
        print_info "Installing optional packages for Fedora/RHEL..."
        dnf install -y -q make vim git-extras 2>/dev/null || print_warning "Some optional packages failed to install"
        
        # Install tflint (optional linter)
        if command -v curl &> /dev/null; then
            print_info "Installing tflint (Terraform linter)..."
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh 2>/dev/null | bash || \
                print_warning "Failed to install tflint"
        fi
    fi
    
    print_success "Optional tools installation complete"
}

# Verify installations
verify_installations() {
    print_header "Verifying Installations"
    
    local tools=("terraform" "curl" "git" "jq" "ssh")
    local missing=0
    
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            local version=$($tool --version 2>/dev/null | head -1)
            print_success "$tool: $version"
        else
            print_error "$tool: NOT FOUND"
            ((missing++))
        fi
    done
    
    if [[ $missing -gt 0 ]]; then
        print_warning "Some tools are missing. Please install them manually."
        return 1
    fi
    
    return 0
}

# Display configuration summary
display_summary() {
    print_header "Installation Summary"
    
    echo -e "${BLUE}Installed Packages:${NC}"
    echo "  • Terraform - Infrastructure as Code tool"
    echo "  • curl/wget - Download utilities"
    echo "  • git - Version control"
    echo "  • jq - JSON processor"
    echo "  • unzip - Archive extraction"
    echo "  • openssh-client - SSH connectivity"
    echo "  • ca-certificates - SSL/TLS certificates"
    
    if [[ $INSTALL_OPTIONAL == true ]]; then
        echo ""
        echo -e "${BLUE}Optional Tools:${NC}"
        echo "  • make - Build automation"
        echo "  • vim - Text editor"
        echo "  • tflint - Terraform linter"
    fi
    
    echo ""
    echo -e "${GREEN}✓ Bootstrap complete!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "  1. Configure your Proxmox credentials:"
    echo "     cp terraform.tfvars.example terraform.tfvars"
    echo "     vim terraform.tfvars"
    echo ""
    echo "  2. Initialize Terraform:"
    echo "     terraform init"
    echo ""
    echo "  3. Review the deployment plan:"
    echo "     terraform plan"
    echo ""
    echo "  4. Deploy the infrastructure:"
    echo "     terraform apply"
    echo ""
    echo -e "${BLUE}For more help:${NC}"
    echo "  • Run: make help"
    echo "  • See: README.md"
    echo "  • Examples: examples.md"
    echo ""
}

##############################################################################
# Main Script
##############################################################################

main() {
    clear
    print_header "Proxmox Terraform Bootstrap Script"
    
    echo "This script will install all required packages for the Proxmox"
    echo "Terraform stack on your Linux host."
    echo ""
    
    # Check if running as root
    check_root
    
    # Detect distribution
    detect_distro
    
    # Update package manager
    update_package_manager
    
    # Install packages based on distro
    case $DISTRO_TYPE in
        debian)
            install_debian_packages
            install_terraform_debian
            ;;
        fedora)
            install_fedora_packages
            install_terraform_fedora
            ;;
    esac
    
    # Install optional tools
    if [[ $INSTALL_OPTIONAL == true ]]; then
        install_optional_tools
    fi
    
    # Verify installations
    if verify_installations; then
        display_summary
        exit 0
    else
        print_warning "Bootstrap completed with warnings. Please review above."
        display_summary
        exit 1
    fi
}

# Run main function
main "$@"
