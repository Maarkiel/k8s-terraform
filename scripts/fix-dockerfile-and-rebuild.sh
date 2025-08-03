#!/bin/bash

# Automatic Dockerfile Fix and Rebuild Script
# This script fixes the PATH issue and rebuilds the image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

echo "🔧 AUTOMATIC DOCKERFILE FIX AND REBUILD"
echo "======================================="
echo ""

# Check if we're in the right directory
if [ ! -f "docker/Dockerfile" ]; then
    print_error "Please run this script from the project root directory (where docker/Dockerfile exists)"
    exit 1
fi

# Step 1: Backup original Dockerfile
print_status "Step 1: Backing up original Dockerfile..."
cp docker/Dockerfile docker/Dockerfile.backup
print_success "Backup saved as docker/Dockerfile.backup"
echo ""

# Step 2: Create fixed Dockerfile
print_status "Step 2: Creating fixed Dockerfile..."
cat > docker/Dockerfile << 'EOF'
# Multi-stage build dla optymalizacji
FROM python:3.11-slim as builder

# Ustawienie katalogu roboczego
WORKDIR /app

# Kopiowanie pliku requirements
COPY app/requirements.txt .

# Instalacja zależności
RUN pip install --no-cache-dir --user -r requirements.txt

# Główny obraz
FROM python:3.11-slim

# Metadane
LABEL maintainer="Portfolio Demo"
LABEL description="K8s + Terraform Portfolio Demo Application"
LABEL version="1.0.0"

# Tworzenie użytkownika bez uprawnień root
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Ustawienie katalogu roboczego
WORKDIR /app

# Kopiowanie zależności z builder stage
COPY --from=builder /root/.local /home/appuser/.local

# Kopiowanie kodu aplikacji
COPY app/ .

# Zmiana właściciela plików
RUN chown -R appuser:appuser /app

# Przełączenie na użytkownika bez uprawnień root
USER appuser

# FIXED: Dodanie ścieżki do PATH AFTER switching user
ENV PATH="/home/appuser/.local/bin:${PATH}"

# Zmienne środowiskowe
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONPATH=/app
ENV PORT=5000

# Eksponowanie portu
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# FIXED: Użyj python -m gunicorn zamiast bezpośredniego gunicorn
CMD ["python", "-m", "gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "--keep-alive", "2", "app:app"]
EOF

print_success "Fixed Dockerfile created with:"
echo "  - PATH set after USER switch"
echo "  - Using 'python -m gunicorn' instead of direct 'gunicorn'"
echo ""

# Step 3: Delete current deployment
print_status "Step 3: Deleting current deployment..."
kubectl delete deployment portfolio-app -n portfolio-demo 2>/dev/null || true
print_success "Deployment deleted"
echo ""

# Step 4: Set Docker environment to minikube
print_status "Step 4: Setting Docker environment to minikube..."
eval $(minikube docker-env)
print_success "Docker environment set to minikube"
echo ""

# Step 5: Remove old image
print_status "Step 5: Removing old image..."
docker rmi portfolio-demo:latest 2>/dev/null || true
print_success "Old image removed"
echo ""

# Step 6: Build new image with fixes
print_status "Step 6: Building new image with fixes..."
print_status "This will take a few minutes..."
docker build -t portfolio-demo:latest -f docker/Dockerfile . --no-cache
print_success "New image built successfully!"
echo ""

# Step 7: Test the fixes
print_status "Step 7: Testing the fixes..."

echo "Testing PATH:"
docker run --rm portfolio-demo:latest echo '$PATH'

echo ""
echo "Testing python -m gunicorn:"
docker run --rm portfolio-demo:latest python -m gunicorn --version

echo ""
echo "Testing if gunicorn is accessible:"
docker run --rm portfolio-demo:latest which gunicorn || echo "Direct gunicorn not in PATH (this is OK if python -m gunicorn works)"

echo ""
echo "Testing user:"
docker run --rm portfolio-demo:latest whoami

print_success "All tests completed!"
echo ""

# Step 8: Test container startup
print_status "Step 8: Testing container startup..."
TEST_CONTAINER=$(docker run -d -p 5001:5000 portfolio-demo:latest)
sleep 10

if curl -s http://localhost:5001/health >/dev/null 2>&1; then
    print_success "✅ Container starts successfully and responds to health check!"
else
    print_warning "⚠️ Container may have startup issues. Checking logs..."
    docker logs $TEST_CONTAINER | tail -10
fi

# Clean up test container
docker stop $TEST_CONTAINER >/dev/null 2>&1
docker rm $TEST_CONTAINER >/dev/null 2>&1
echo ""

# Step 9: Reset Docker environment
print_status "Step 9: Resetting Docker environment..."
eval $(minikube docker-env -u)
print_success "Docker environment reset"
echo ""

# Step 10: Deploy the application
print_status "Step 10: Deploying the application..."
kubectl apply -f k8s/deployment.yaml
print_success "Deployment applied"
echo ""

# Step 11: Wait for pods
print_status "Step 11: Waiting for pods to start (60 seconds)..."
sleep 60
echo ""

# Step 12: Check final status
print_status "Step 12: Checking final pod status..."
kubectl get pods -n portfolio-demo
echo ""

# Check if pods are running
POD_STATUS=$(kubectl get pods -n portfolio-demo -l app=portfolio-app -o jsonpath='{.items[0].status.phase}' 2>/dev/null || echo "Unknown")

if [ "$POD_STATUS" = "Running" ]; then
    print_success "🎉 SUCCESS! Pods are running!"
    
    # Get access information
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "localhost")
    NODEPORT=$(kubectl get service portfolio-nodeport -n portfolio-demo -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "30080")
    
    echo ""
    echo "🌐 Your application is now accessible at:"
    echo "   http://${MINIKUBE_IP}:${NODEPORT}"
    echo ""
    echo "📊 Useful commands:"
    echo "   kubectl logs -f deployment/portfolio-app -n portfolio-demo"
    echo "   kubectl get pods -n portfolio-demo"
    
else
    print_warning "⚠️ Pods may still be starting or have issues. Checking logs..."
    POD_NAME=$(kubectl get pods -n portfolio-demo -l app=portfolio-app -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$POD_NAME" ]; then
        echo ""
        echo "Recent pod logs:"
        kubectl logs $POD_NAME -n portfolio-demo --tail=20 || true
    fi
fi

echo ""
print_status "🔧 Dockerfile fix and rebuild completed!"
echo ""
echo "Changes made:"
echo "1. ✅ Fixed PATH environment variable"
echo "2. ✅ Changed CMD to use 'python -m gunicorn'"
echo "3. ✅ Rebuilt image in minikube"
echo "4. ✅ Redeployed application"
echo ""
echo "Original Dockerfile backed up as: docker/Dockerfile.backup"

