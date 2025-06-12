#!/bin/bash

# Minecraft Server Destroy Script
# This script destroys all AWS resources created for the Minecraft server

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="."

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

confirm_destroy() {
    log_warning "This will destroy ALL AWS resources created for the Minecraft server!"
    log_warning "This action cannot be undone."
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Destruction cancelled."
        exit 0
    fi
}

terraform_destroy() {
    log_info "Starting Terraform destroy..."
    
    cd "$TERRAFORM_DIR"
    
    # Show what will be destroyed
    log_info "Planning destruction..."
    terraform plan -destroy
    
    echo ""
    log_warning "The above resources will be DESTROYED!"
    read -p "Continue with destruction? (yes/no): " -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Destruction cancelled."
        exit 0
    fi
    
    # Destroy resources
    log_info "Destroying AWS resources..."
    terraform destroy -auto-approve
    
    log_success "All AWS resources have been destroyed"
}

cleanup_local_files() {
    log_info "Cleaning up local files..."
    
    # Remove Terraform state files (optional)
    read -p "Do you want to remove local Terraform state files? (yes/no): " -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        rm -f terraform.tfstate*
        rm -rf .terraform/
        log_success "Local Terraform files cleaned up"
    fi
}

main() {
    log_info "Starting Minecraft Server destruction..."
    
    # Confirm destruction
    confirm_destroy
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed."
        exit 1
    fi
    
    # Check if terraform is initialized
    if [ ! -d ".terraform" ]; then
        log_error "Terraform is not initialized. Run 'terraform init' first."
        exit 1
    fi
    
    # Destroy resources
    terraform_destroy
    
    # Optional cleanup
    cleanup_local_files
    
    log_success "Minecraft server destruction completed!"
}

# Run main function
main "$@" 