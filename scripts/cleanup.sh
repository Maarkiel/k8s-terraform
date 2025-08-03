#!/bin/bash

# K8s + Terraform Portfolio Demo - Cleanup Script
# This script cleans up all resources created by the demo

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Starting cleanup of K8s + Terraform Portfolio Demo..."

# Change to terraform directory
cd "$(dirname "$0")/../terraform"

# Check if terraform state exists
if [ ! -f "terraform.tfstate" ]; then
    print_warning "No Terraform state found. Nothing to destroy."
else
    # Ask for confirmation
    echo ""
    print_warning "This will destroy all resources created by Terraform."
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Cleanup cancelled by user"
        exit 0
    fi

    # Terraform destroy
    print_status "Destroying Terraform resources..."
    terraform destroy -auto-approve
    print_success "Terraform resources destroyed"
fi

# Additional cleanup - remove any remaining resources manually
print_status "Performing additional cleanup..."

# Delete namespace (this will delete all resources in the namespace)
kubectl delete namespace portfolio-demo --ignore-not-found=true
print_success "Namespace portfolio-demo deleted"

# Clean up Docker images
print_status "Cleaning up Docker images..."
docker rmi portfolio-demo:latest 2>/dev/null || print_warning "Docker image portfolio-demo:latest not found"

# Remove image from minikube
minikube image rm portfolio-demo:latest 2>/dev/null || print_warning "Image not found in minikube"

print_success "Cleanup completed successfully!"

echo ""
print_status "Optional: You can also stop minikube if you don't need it:"
echo "  minikube stop"
echo ""
print_status "Or delete the entire minikube cluster:"
echo "  minikube delete"
echo ""

