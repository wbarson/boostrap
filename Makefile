.PHONY: help init plan apply destroy validate fmt clean console

help:
	@echo "Proxmox Terraform Stack - Available Commands"
	@echo ""
	@echo "  make init          - Initialize Terraform working directory"
	@echo "  make plan          - Generate and show execution plan"
	@echo "  make apply         - Apply the Terraform configuration"
	@echo "  make destroy       - Destroy all managed resources"
	@echo "  make validate      - Validate the configuration"
	@echo "  make fmt           - Format Terraform files"
	@echo "  make show          - Display current state"
	@echo "  make state-list    - List resources in state"
	@echo "  make output        - Show output values"
	@echo "  make clean         - Remove local .terraform directory"
	@echo "  make console       - Open Terraform console"
	@echo ""

init:
	@echo "Initializing Terraform..."
	terraform init

validate:
	@echo "Validating Terraform configuration..."
	terraform validate

fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

plan:
	@echo "Planning Terraform changes..."
	terraform plan -out=tfplan

apply:
	@echo "Applying Terraform configuration..."
	terraform apply tfplan
	@rm -f tfplan

apply-force:
	@echo "Applying Terraform configuration (without plan review)..."
	terraform apply -auto-approve

destroy:
	@echo "This will destroy all managed resources!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] && terraform destroy

destroy-force:
	@echo "Destroying all managed resources..."
	terraform destroy -auto-approve

show:
	@echo "Showing current state..."
	terraform show

state-list:
	@echo "Listing resources in state..."
	terraform state list

output:
	@echo "Showing outputs..."
	terraform output

clean:
	@echo "Cleaning up local Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f tfplan

console:
	terraform console

# Development/debugging targets
validate-syntax:
	terraform validate

check-lock:
	@cat .terraform.lock.hcl 2>/dev/null || echo "No lock file found"

get-modules:
	@echo "Getting Terraform modules and providers..."
	terraform get -update

refresh:
	@echo "Refreshing Terraform state..."
	terraform refresh

# Target specific VM
plan-vm:
	@echo "Usage: make plan-vm VM_NAME=web-server-1"
	@if [ -n "$(VM_NAME)" ]; then \
		terraform plan -target='proxmox_vm_qemu.vm["$(VM_NAME)"]'; \
	fi

destroy-vm:
	@echo "Usage: make destroy-vm VM_NAME=web-server-1"
	@if [ -n "$(VM_NAME)" ]; then \
		terraform destroy -target='proxmox_vm_qemu.vm["$(VM_NAME)"]'; \
	fi

# Lock and unlock state
lock-state:
	@echo "This command requires backend configuration"
	terraform force-unlock <lock-id>

# Generate docs
docs:
	@echo "Generating Terraform documentation..."
	terraform-docs markdown . > /tmp/terraform-docs.md
	@echo "Documentation generated to /tmp/terraform-docs.md"

# Lint configuration
lint: fmt validate
	@echo "Linting complete!"

# All-in-one setup
setup: init validate fmt plan
	@echo "Setup complete! Review the plan above."

.DEFAULT_GOAL := help
