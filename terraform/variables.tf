# Kubernetes Configuration
variable "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "minikube"
}

# Application Configuration
variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "portfolio-app"
}

variable "app_version" {
  description = "Version of the application"
  type        = string
  default     = "1.0.0"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "portfolio-demo"
}

variable "environment" {
  description = "Environment (development, staging, production)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production."
  }
}

# Deployment Configuration
variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 3
  
  validation {
    condition     = var.replicas >= 1 && var.replicas <= 10
    error_message = "Replicas must be between 1 and 10."
  }
}

variable "image_name" {
  description = "Docker image name"
  type        = string
  default     = "portfolio-demo"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 5000
}

# Service Configuration
variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"
  
  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "Service type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
}

variable "service_port" {
  description = "Service port"
  type        = number
  default     = 80
}

variable "nodeport_port" {
  description = "NodePort port (if service_type is NodePort)"
  type        = number
  default     = 30080
}

# Resource Limits
variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "100m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "128Mi"
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "200m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "256Mi"
}

# HPA Configuration
variable "enable_hpa" {
  description = "Enable Horizontal Pod Autoscaler"
  type        = bool
  default     = true
}

variable "hpa_min_replicas" {
  description = "Minimum replicas for HPA"
  type        = number
  default     = 2
}

variable "hpa_max_replicas" {
  description = "Maximum replicas for HPA"
  type        = number
  default     = 10
}

variable "hpa_cpu_threshold" {
  description = "CPU threshold for HPA"
  type        = number
  default     = 70
}

variable "hpa_memory_threshold" {
  description = "Memory threshold for HPA"
  type        = number
  default     = 80
}

# Ingress Configuration
variable "enable_ingress" {
  description = "Enable Ingress"
  type        = bool
  default     = true
}

variable "ingress_host" {
  description = "Ingress host"
  type        = string
  default     = "portfolio-demo.local"
}

variable "ingress_class" {
  description = "Ingress class"
  type        = string
  default     = "nginx"
}

# Labels and Annotations
variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default = {
    project     = "k8s-terraform-portfolio"
    managed-by  = "terraform"
    component   = "demo"
  }
}

variable "common_annotations" {
  description = "Common annotations to apply to all resources"
  type        = map(string)
  default = {
    "project.description" = "K8s + Terraform Portfolio Demo"
    "deployment.tool"     = "terraform"
  }
}

