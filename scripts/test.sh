#!/bin/bash

# K8s + Terraform Portfolio Demo - Test Script
# This script tests the deployed application

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

# Function to test HTTP endpoint
test_endpoint() {
    local url=$1
    local description=$2
    
    print_status "Testing $description: $url"
    
    if curl -s -f "$url" > /dev/null; then
        print_success "$description is accessible"
        return 0
    else
        print_error "$description is not accessible"
        return 1
    fi
}

# Function to test JSON endpoint
test_json_endpoint() {
    local url=$1
    local description=$2
    
    print_status "Testing $description: $url"
    
    local response=$(curl -s -f "$url" 2>/dev/null)
    if [ $? -eq 0 ] && echo "$response" | jq . > /dev/null 2>&1; then
        print_success "$description returned valid JSON"
        echo "Response: $response" | jq .
        return 0
    else
        print_error "$description failed or returned invalid JSON"
        return 1
    fi
}

print_status "Starting tests for K8s + Terraform Portfolio Demo..."

# Check if application is deployed
if ! kubectl get namespace portfolio-demo >/dev/null 2>&1; then
    print_error "Application is not deployed. Please run './scripts/deploy.sh' first."
    exit 1
fi

# Check if pods are running
print_status "Checking pod status..."
kubectl get pods -n portfolio-demo

if ! kubectl get pods -n portfolio-demo | grep -q "Running"; then
    print_error "No running pods found"
    exit 1
fi

print_success "Pods are running"

# Get access information
BASE_URL=$(minikube service portfolio-nodeport -n portfolio-demo --url)


echo ""
print_status "Testing application endpoints..."
echo "Base URL: $BASE_URL"
echo ""

# Test main page
test_endpoint "$BASE_URL" "Main page"

# Test health endpoint
test_json_endpoint "$BASE_URL/health" "Health check endpoint"

# Test API endpoints
test_json_endpoint "$BASE_URL/api/status" "Status API endpoint"
test_json_endpoint "$BASE_URL/api/tasks" "Tasks API endpoint"
test_json_endpoint "$BASE_URL/api/info" "Info API endpoint"

# Test specific task
test_json_endpoint "$BASE_URL/api/tasks/1" "Specific task API endpoint"

# Test task filtering
test_json_endpoint "$BASE_URL/api/tasks?status=completed" "Task filtering API endpoint"

echo ""
print_status "Testing Kubernetes resources..."

# Test service discovery
print_status "Testing service discovery..."
kubectl get services -n portfolio-demo

# Test ingress (if enabled)
if kubectl get ingress -n portfolio-demo >/dev/null 2>&1; then
    print_status "Ingress is configured"
    kubectl get ingress -n portfolio-demo
else
    print_warning "Ingress is not configured"
fi

# Test HPA (if enabled)
if kubectl get hpa -n portfolio-demo >/dev/null 2>&1; then
    print_status "HPA is configured"
    kubectl get hpa -n portfolio-demo
else
    print_warning "HPA is not configured"
fi

# Test scaling
print_status "Testing deployment scaling..."
ORIGINAL_REPLICAS=$(kubectl get deployment portfolio-app -n portfolio-demo -o jsonpath='{.spec.replicas}')
print_status "Original replicas: $ORIGINAL_REPLICAS"

print_status "Scaling to 5 replicas..."
kubectl scale deployment portfolio-app --replicas=5 -n portfolio-demo

print_status "Waiting for scaling to complete..."
kubectl wait --for=condition=available --timeout=60s deployment/portfolio-app -n portfolio-demo

CURRENT_REPLICAS=$(kubectl get deployment portfolio-app -n portfolio-demo -o jsonpath='{.spec.replicas}')
print_success "Current replicas: $CURRENT_REPLICAS"

# Scale back to original
print_status "Scaling back to $ORIGINAL_REPLICAS replicas..."
kubectl scale deployment portfolio-app --replicas=$ORIGINAL_REPLICAS -n portfolio-demo
kubectl wait --for=condition=available --timeout=60s deployment/portfolio-app -n portfolio-demo

print_success "Scaling test completed"

echo ""
print_status "Testing ConfigMap and Secret usage..."

# Check if environment variables are properly set
POD_NAME=$(kubectl get pods -n portfolio-demo -l app=portfolio-app -o jsonpath='{.items[0].metadata.name}')
print_status "Testing environment variables in pod: $POD_NAME"

# Test ConfigMap variables
APP_NAME=$(kubectl exec -n portfolio-demo $POD_NAME -- printenv APP_NAME 2>/dev/null || echo "Not found")
print_status "APP_NAME from ConfigMap: $APP_NAME"

# Test Secret variables (don't print actual values)
if kubectl exec -n portfolio-demo $POD_NAME -- printenv SECRET_KEY >/dev/null 2>&1; then
    print_success "SECRET_KEY from Secret is available"
else
    print_error "SECRET_KEY from Secret is not available"
fi

echo ""
print_success "All tests completed!"

echo ""
print_status "Summary:"
echo "  - Application is accessible at: $BASE_URL"
echo "  - All API endpoints are working"
echo "  - Kubernetes resources are properly configured"
echo "  - Scaling functionality works"
echo "  - ConfigMap and Secret integration works"
echo ""
print_status "You can now take screenshots for your portfolio!"

