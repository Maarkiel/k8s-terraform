# Namespace outputs
output "namespace_name" {
  description = "Name of the created namespace"
  value       = kubernetes_namespace.portfolio.metadata[0].name
}

# Deployment outputs
output "deployment_name" {
  description = "Name of the deployment"
  value       = kubernetes_deployment.portfolio_app.metadata[0].name
}

output "deployment_replicas" {
  description = "Number of replicas in the deployment"
  value       = kubernetes_deployment.portfolio_app.spec[0].replicas
}

output "deployment_image" {
  description = "Docker image used in the deployment"
  value       = "${var.image_name}:${var.image_tag}"
}

# Service outputs
output "clusterip_service_name" {
  description = "Name of the ClusterIP service"
  value       = kubernetes_service.portfolio_service.metadata[0].name
}

output "clusterip_service_ip" {
  description = "Cluster IP of the service"
  value       = kubernetes_service.portfolio_service.spec[0].cluster_ip
}

output "nodeport_service_name" {
  description = "Name of the NodePort service"
  value       = kubernetes_service.portfolio_nodeport.metadata[0].name
}

output "nodeport_port" {
  description = "NodePort port number"
  value       = kubernetes_service.portfolio_nodeport.spec[0].port[0].node_port
}

# Ingress outputs
output "ingress_name" {
  description = "Name of the ingress"
  value       = var.enable_ingress ? kubernetes_ingress_v1.portfolio_ingress[0].metadata[0].name : null
}

output "ingress_host" {
  description = "Ingress host"
  value       = var.enable_ingress ? var.ingress_host : null
}

output "ingress_url" {
  description = "Full URL for accessing the application via ingress"
  value       = var.enable_ingress ? "http://${var.ingress_host}" : null
}

# HPA outputs
output "hpa_name" {
  description = "Name of the Horizontal Pod Autoscaler"
  value       = var.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.portfolio_hpa[0].metadata[0].name : null
}

output "hpa_min_replicas" {
  description = "Minimum replicas for HPA"
  value       = var.enable_hpa ? var.hpa_min_replicas : null
}

output "hpa_max_replicas" {
  description = "Maximum replicas for HPA"
  value       = var.enable_hpa ? var.hpa_max_replicas : null
}

# ConfigMap and Secret outputs
output "configmap_name" {
  description = "Name of the ConfigMap"
  value       = kubernetes_config_map.portfolio_config.metadata[0].name
}

output "secret_name" {
  description = "Name of the Secret"
  value       = kubernetes_secret.portfolio_secrets.metadata[0].name
}

# Access information
output "access_methods" {
  description = "Different ways to access the application"
  value = {
    nodeport = "http://$(minikube ip):${kubernetes_service.portfolio_nodeport.spec[0].port[0].node_port}"
    ingress  = var.enable_ingress ? "http://${var.ingress_host} (add to /etc/hosts)" : "Ingress disabled"
    kubectl_port_forward = "kubectl port-forward -n ${kubernetes_namespace.portfolio.metadata[0].name} svc/${kubernetes_service.portfolio_service.metadata[0].name} 8080:${var.service_port}"
  }
}

# Resource summary
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    namespace    = kubernetes_namespace.portfolio.metadata[0].name
    deployment   = kubernetes_deployment.portfolio_app.metadata[0].name
    services     = [
      kubernetes_service.portfolio_service.metadata[0].name,
      kubernetes_service.portfolio_nodeport.metadata[0].name
    ]
    configmap    = kubernetes_config_map.portfolio_config.metadata[0].name
    secret       = kubernetes_secret.portfolio_secrets.metadata[0].name
    ingress      = var.enable_ingress ? kubernetes_ingress_v1.portfolio_ingress[0].metadata[0].name : "Not created"
    hpa          = var.enable_hpa ? kubernetes_horizontal_pod_autoscaler_v2.portfolio_hpa[0].metadata[0].name : "Not created"
  }
}

# Useful commands
output "useful_commands" {
  description = "Useful kubectl commands for this deployment"
  value = {
    get_pods     = "kubectl get pods -n ${kubernetes_namespace.portfolio.metadata[0].name}"
    get_services = "kubectl get services -n ${kubernetes_namespace.portfolio.metadata[0].name}"
    get_ingress  = "kubectl get ingress -n ${kubernetes_namespace.portfolio.metadata[0].name}"
    get_hpa      = "kubectl get hpa -n ${kubernetes_namespace.portfolio.metadata[0].name}"
    describe_deployment = "kubectl describe deployment ${kubernetes_deployment.portfolio_app.metadata[0].name} -n ${kubernetes_namespace.portfolio.metadata[0].name}"
    logs         = "kubectl logs -f deployment/${kubernetes_deployment.portfolio_app.metadata[0].name} -n ${kubernetes_namespace.portfolio.metadata[0].name}"
    scale        = "kubectl scale deployment ${kubernetes_deployment.portfolio_app.metadata[0].name} --replicas=5 -n ${kubernetes_namespace.portfolio.metadata[0].name}"
  }
}

