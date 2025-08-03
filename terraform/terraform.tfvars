# Kubernetes Configuration
kubeconfig_path = "~/.kube/config"
kube_context    = "minikube"

# Application Configuration
app_name    = "portfolio-app"
app_version = "1.0.0"
namespace   = "portfolio-demo"
environment = "production"

# Deployment Configuration
replicas      = 3
image_name    = "portfolio-demo"
image_tag     = "latest"
container_port = 5000

# Service Configuration
service_type   = "ClusterIP"
service_port   = 80
nodeport_port  = 30081

# Resource Configuration
cpu_request    = "100m"
memory_request = "128Mi"
cpu_limit      = "200m"
memory_limit   = "256Mi"

# HPA Configuration
enable_hpa           = true
hpa_min_replicas     = 2
hpa_max_replicas     = 10
hpa_cpu_threshold    = 70
hpa_memory_threshold = 80

# Ingress Configuration
enable_ingress  = true
ingress_host    = "portfolio-demo.local"
ingress_class   = "nginx"

# Labels and Annotations
common_labels = {
  project    = "k8s-terraform-portfolio"
  managed-by = "terraform"
  component  = "demo"
  team       = "devops"
}

common_annotations = {
  "project.description" = "K8s + Terraform Portfolio Demo"
  "deployment.tool"     = "terraform"
  "deployment.date"     = "2025-01-08"
}

