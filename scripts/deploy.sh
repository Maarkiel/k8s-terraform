#!/bin/bash

# K8s + Terraform Portfolio Demo - Deploy Script
# This script deploys the application using Terraform

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

# Function to check if minikube is running
is_minikube_running() {
    minikube status >/dev/null 2>&1
}

print_status "Starting deployment of K8s + Terraform Portfolio Demo..."

# Check if minikube is running
if ! is_minikube_running; then
    print_error "minikube is not running. Please run './scripts/setup.sh' first."
    exit 1
fi

# Change to terraform directory
cd "$(dirname "$0")/../terraform"

# Terraform plan
print_status "Running Terraform plan..."
terraform plan -out=tfplan
print_success "Terraform plan completed"

# Ask for confirmation
echo ""
read -p "Do you want to apply the Terraform plan? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled by user"
    rm -f tfplan
    exit 0
fi

# Terraform apply
print_status "Applying Terraform configuration..."
terraform apply tfplan
rm -f tfplan
print_success "Terraform apply completed"

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/portfolio-app -n portfolio-demo
print_success "Deployment is ready"

# Get deployment information
print_status "Getting deployment information..."
echo ""
echo "=== DEPLOYMENT INFORMATION ==="
echo ""

# Namespace
echo "Namespace:"
kubectl get namespace portfolio-demo

echo ""
echo "Pods:"
kubectl get pods -n portfolio-demo -o wide

echo ""
echo "Services:"
kubectl get services -n portfolio-demo

echo ""
echo "Ingress:"
kubectl get ingress -n portfolio-demo 2>/dev/null || echo "No ingress found"

echo ""
echo "HPA:"
kubectl get hpa -n portfolio-demo 2>/dev/null || echo "No HPA found"

echo ""
echo "=== ACCESS INFORMATION ==="
echo ""

# Get minikube IP
MINIKUBE_IP=$(minikube ip)
NODEPORT=$(kubectl get service portfolio-nodeport -n portfolio-demo -o jsonpath='{.spec.ports[0].nodePort}')

echo "Application access methods:"
echo "  1. NodePort: http://${MINIKUBE_IP}:${NODEPORT}"
echo "  2. Port Forward: kubectl port-forward -n portfolio-demo svc/portfolio-service 8080:80"
echo "     Then access: http://localhost:8080"
echo "  3. Ingress: http://portfolio-demo.local (add '${MINIKUBE_IP} portfolio-demo.local' to /etc/hosts)"

echo ""
echo "=== USEFUL COMMANDS ==="
echo ""
echo "View logs:"
echo "  kubectl logs -f deployment/portfolio-app -n portfolio-demo"
echo ""
echo "Scale deployment:"
echo "  kubectl scale deployment portfolio-app --replicas=5 -n portfolio-demo"
echo ""
echo "Port forward:"
echo "  kubectl port-forward -n portfolio-demo svc/portfolio-service 8080:80"
echo ""
echo "Access minikube dashboard:"
echo "  minikube dashboard"
echo ""

print_success "Deployment completed successfully!"
print_status "Application is now running and accessible via the methods listed above"

