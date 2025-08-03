# Kubernetes Provider
provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

# Helm Provider
provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

# Local Provider
provider "local" {}

# Null Provider
provider "null" {}

