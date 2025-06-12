#!/bin/bash

# Minecraft Server Deployment Script
# This script automates the complete deployment of a Minecraft server on AWS

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="."
SSH_KEY_NAME="minecraft-key"
SSH_DIR="$HOME/.ssh"
PRIVATE_KEY_PATH="$SSH_DIR/${SSH_KEY_NAME}.pem"
PUBLIC_KEY_PATH="$SSH_DIR/${SSH_KEY_NAME}.pub"

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

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if ansible is installed
    if ! command -v ansible &> /dev/null; then
        log_error "Ansible is not installed. Please install Ansible first."
        exit 1
    fi
    
    # Check if aws cli is configured
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS CLI is not configured. Please configure AWS credentials first."
        exit 1
    fi
    
    log_success "All prerequisites are satisfied"
}

generate_ssh_keys() {
    log_info "Checking SSH keys..."
    
    if [ ! -f "$PRIVATE_KEY_PATH" ] || [ ! -f "$PUBLIC_KEY_PATH" ]; then
        log_info "Generating SSH key pair..."
        
        # Create SSH directory if it doesn't exist
        mkdir -p "$SSH_DIR"
        
        # Generate SSH key pair
        ssh-keygen -t rsa -b 4096 -f "$PRIVATE_KEY_PATH" -N "" -C "minecraft-server-key"
        
        # Set proper permissions
        chmod 600 "$PRIVATE_KEY_PATH"
        chmod 644 "$PUBLIC_KEY_PATH"
        
        log_success "SSH key pair generated successfully"
    else
        log_info "SSH key pair already exists"
    fi
}

terraform_deploy() {
    log_info "Starting Terraform deployment..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    # Plan deployment
    log_info "Planning Terraform deployment..."
    terraform plan -var="private_key_path=$PRIVATE_KEY_PATH" -var="public_key_path=$PUBLIC_KEY_PATH"
    
    # Apply deployment
    log_info "Applying Terraform deployment..."
    terraform apply -auto-approve -var="private_key_path=$PRIVATE_KEY_PATH" -var="public_key_path=$PUBLIC_KEY_PATH"
    
    log_success "Terraform deployment completed"
}

get_server_info() {
    log_info "Retrieving server information..."
    
    cd "$TERRAFORM_DIR"
    
    # Get server IP
    SERVER_IP=$(terraform output -raw minecraft_server_public_ip)
    NMAP_COMMAND=$(terraform output -raw minecraft_server_connection_command)
    SERVER_ADDRESS=$(terraform output -raw minecraft_server_address)
    
    log_success "Server deployed successfully!"
    echo ""
    echo "=========================================="
    echo "  MINECRAFT SERVER DEPLOYMENT COMPLETE"
    echo "=========================================="
    echo "Server IP Address: $SERVER_IP"
    echo "Server Address: $SERVER_ADDRESS"
    echo "Test Command: $NMAP_COMMAND"
    echo "=========================================="
    echo ""
}

test_connection() {
    log_info "Testing server connection..."
    
    if command -v nmap &> /dev/null; then
        log_info "Running nmap test..."
        if nmap -sV -Pn -p T:25565 "$SERVER_IP" | grep -q "25565/tcp open"; then
            log_success "Minecraft server is running and accessible!"
        else
            log_warning "Minecraft server might still be starting up. Please wait a few minutes and try again."
        fi
    else
        log_warning "nmap is not installed. Please install nmap to test the connection."
    fi
}

cleanup_on_error() {
    log_error "Deployment failed. You may need to clean up resources manually."
    log_info "To destroy resources, run: terraform destroy"
}

main() {
    log_info "Starting Minecraft Server deployment..."
    
    # Set up error handling
    trap cleanup_on_error ERR
    
    # Run deployment steps
    check_prerequisites
    generate_ssh_keys
    terraform_deploy
    get_server_info
    
    # Wait a bit before testing
    log_info "Waiting 60 seconds for server to fully start..."
    sleep 60
    
    test_connection
    
    log_success "Deployment completed successfully!"
    log_info "You can now connect to your Minecraft server at: $SERVER_ADDRESS"
}

# Run main function
main "$@" 