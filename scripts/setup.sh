#!/bin/bash

# K8s + Terraform Portfolio Demo - Setup Script
# This script sets up the local environment for the demo

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if minikube is running
is_minikube_running() {
    minikube status >/dev/null 2>&1
}

print_status "Starting K8s + Terraform Portfolio Demo Setup..."

# Check prerequisites
print_status "Checking prerequisites..."

# Check Docker
if ! command_exists docker; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker first."
    exit 1
fi

print_success "Docker is installed and running"

# Check minikube
if ! command_exists minikube; then
    print_error "minikube is not installed. Please install minikube first."
    print_status "Installation guide: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

print_success "minikube is installed"

# Check kubectl
if ! command_exists kubectl; then
    print_error "kubectl is not installed. Please install kubectl first."
    print_status "Installation guide: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

print_success "kubectl is installed"

# Check Terraform
if ! command_exists terraform; then
    print_error "Terraform is not installed. Please install Terraform first."
    print_status "Installation guide: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

print_success "Terraform is installed"

# Start minikube if not running
if ! is_minikube_running; then
    print_status "Starting minikube..."
    minikube start --driver=docker --cpus=2 --memory=4096
    print_success "minikube started"
else
    print_success "minikube is already running"
fi

# Enable required addons
print_status "Enabling minikube addons..."
minikube addons enable ingress
minikube addons enable metrics-server
print_success "minikube addons enabled"

# Set kubectl context
print_status "Setting kubectl context to minikube..."
kubectl config use-context minikube
print_success "kubectl context set to minikube"

# Build Docker image
print_status "Building Docker image..."
cd "$(dirname "$0")/.."

# Use Minikube Docker daemon
eval $(minikube docker-env)
docker build -t portfolio-demo:latest -f Dockerfile .
print_success "Docker image built: portfolio-demo:latest"

# Load image into minikube
print_status "Loading Docker image into minikube..."
# minikube image load portfolio-demo:latest
print_success "Docker image loaded into minikube"

# Initialize Terraform
print_status "Initializing Terraform..."
cd terraform
terraform init
print_success "Terraform initialized"

print_success "Setup completed successfully!"
print_status "You can now run './scripts/deploy.sh' to deploy the application"

# Display useful information
echo ""
print_status "Useful information:"
echo "  - minikube IP: $(minikube ip)"
echo "  - minikube dashboard: minikube dashboard"
echo "  - kubectl context: $(kubectl config current-context)"
echo ""

