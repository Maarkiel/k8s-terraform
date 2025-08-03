# K8s + Terraform Portfolio Demo - Makefile
# Simplified commands for common operations

.PHONY: help setup deploy test cleanup status logs scale dashboard build

# Default target
help: ## Show this help message
	@echo "K8s + Terraform Portfolio Demo"
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Setup the local environment (minikube, build image, etc.)
	@echo "Setting up the environment..."
	./scripts/setup.sh

deploy: ## Deploy the application using Terraform
	@echo "Deploying the application..."
	./scripts/deploy.sh

test: ## Test the deployed application
	@echo "Testing the application..."
	./scripts/test.sh

cleanup: ## Clean up all resources
	@echo "Cleaning up resources..."
	./scripts/cleanup.sh

status: ## Show status of all resources
	@echo "=== Minikube Status ==="
	minikube status || echo "Minikube is not running"
	@echo ""
	@echo "=== Kubernetes Resources ==="
	kubectl get all -n portfolio-demo 2>/dev/null || echo "No resources found in portfolio-demo namespace"
	@echo ""
	@echo "=== Terraform State ==="
	cd terraform && terraform show 2>/dev/null || echo "No Terraform state found"

logs: ## Show application logs
	@echo "Showing application logs..."
	kubectl logs -f deployment/portfolio-app -n portfolio-demo

scale: ## Scale the application (usage: make scale REPLICAS=5)
	@echo "Scaling application to $(REPLICAS) replicas..."
	kubectl scale deployment portfolio-app --replicas=$(REPLICAS) -n portfolio-demo
	kubectl wait --for=condition=available --timeout=60s deployment/portfolio-app -n portfolio-demo

dashboard: ## Open minikube dashboard
	@echo "Opening minikube dashboard..."
	minikube dashboard

build: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t portfolio-demo:latest -f docker/Dockerfile .
	minikube image load portfolio-demo:latest

# Development targets
dev-setup: setup ## Setup for development (same as setup)

dev-deploy: build deploy ## Build and deploy for development

dev-test: test ## Test for development (same as test)

# Port forwarding
port-forward: ## Start port forwarding to access the application locally
	@echo "Starting port forwarding on http://localhost:8080"
	@echo "Press Ctrl+C to stop"
	kubectl port-forward -n portfolio-demo svc/portfolio-service 8080:80

# Quick access to application
open: ## Open the application in browser (via NodePort)
	@MINIKUBE_IP=$$(minikube ip); \
	NODEPORT=$$(kubectl get service portfolio-nodeport -n portfolio-demo -o jsonpath='{.spec.ports[0].nodePort}'); \
	echo "Opening http://$$MINIKUBE_IP:$$NODEPORT"; \
	python3 -c "import webbrowser; webbrowser.open('http://$$MINIKUBE_IP:$$NODEPORT')" 2>/dev/null || \
	echo "Please open http://$$MINIKUBE_IP:$$NODEPORT in your browser"

# Terraform specific targets
tf-init: ## Initialize Terraform
	cd terraform && terraform init

tf-plan: ## Run Terraform plan
	cd terraform && terraform plan

tf-apply: ## Apply Terraform configuration
	cd terraform && terraform apply

tf-destroy: ## Destroy Terraform resources
	cd terraform && terraform destroy

# Kubernetes specific targets
k8s-apply: ## Apply Kubernetes manifests directly (without Terraform)
	kubectl apply -f k8s/

k8s-delete: ## Delete Kubernetes manifests directly
	kubectl delete -f k8s/ --ignore-not-found=true

# Docker specific targets
docker-build: build ## Build Docker image (alias for build)

docker-run: ## Run Docker container locally for testing
	docker run -p 5000:5000 --rm portfolio-demo:latest

# Utility targets
get-ip: ## Get minikube IP
	@minikube ip

get-url: ## Get application URL
	@MINIKUBE_IP=$$(minikube ip); \
	NODEPORT=$$(kubectl get service portfolio-nodeport -n portfolio-demo -o jsonpath='{.spec.ports[0].nodePort}'); \
	echo "http://$$MINIKUBE_IP:$$NODEPORT"

describe: ## Describe all resources
	@echo "=== Deployment ==="
	kubectl describe deployment portfolio-app -n portfolio-demo
	@echo ""
	@echo "=== Services ==="
	kubectl describe services -n portfolio-demo
	@echo ""
	@echo "=== Pods ==="
	kubectl describe pods -n portfolio-demo

# Screenshot helpers
screenshot-prep: ## Prepare for taking screenshots
	@echo "Preparing for screenshots..."
	@echo "1. Application URL: $$(make get-url)"
	@echo "2. Opening minikube dashboard in background..."
	@minikube dashboard &
	@echo "3. Use 'make status' to show resource status"
	@echo "4. Use 'make logs' to show application logs"
	@echo "5. Use 'make describe' for detailed resource information"

# Default values for variables
REPLICAS ?= 3

