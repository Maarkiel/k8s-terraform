# Namespace
resource "kubernetes_namespace" "portfolio" {
  metadata {
    name = var.namespace
    
    labels = merge(var.common_labels, {
      name    = var.namespace
      purpose = "demo"
    })
    
    annotations = merge(var.common_annotations, {
      description  = "Namespace for K8s + Terraform portfolio demonstration"
      created-by   = "terraform"
    })
  }
}

# ConfigMap
resource "kubernetes_config_map" "portfolio_config" {
  metadata {
    name      = "portfolio-config"
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app       = var.app_name
      component = "config"
    })
  }

  data = {
    APP_NAME     = "K8s-Terraform Portfolio Demo"
    APP_VERSION  = var.app_version
    ENVIRONMENT  = var.environment
    FLASK_ENV    = "production"
    PORT         = tostring(var.container_port)
    LOG_LEVEL    = "INFO"
    WORKERS      = "2"
    TIMEOUT      = "60"
  }
}

# Secret
resource "kubernetes_secret" "portfolio_secrets" {
  metadata {
    name      = "portfolio-secrets"
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app       = var.app_name
      component = "secrets"
    })
  }

  type = "Opaque"

  data = {
    SECRET_KEY   = base64encode("demo-secret-password")
    API_KEY      = base64encode("demo-api-key-12345")
    DATABASE_URL = base64encode("postgresql://user:pass@localhost:5432/demo")
  }
}

# Deployment
resource "kubernetes_deployment" "portfolio_app" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app     = var.app_name
      version = "v${var.app_version}"
      component = "backend"
    })
  }

  spec {
    replicas = var.replicas

    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "1"
        max_unavailable = "1"
      }
    }

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = merge(var.common_labels, {
          app       = var.app_name
          version   = "v${var.app_version}"
          component = "backend"
        })
        
        annotations = merge(var.common_annotations, {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = tostring(var.container_port)
          "prometheus.io/path"   = "/health"
        })
      }

      spec {
        container {
          name  = var.app_name
          image = "${var.image_name}:${var.image_tag}"
          image_pull_policy = "Never"  # For local images

          port {
            container_port = var.container_port
            name          = "http"
            protocol      = "TCP"
          }

          # Environment variables from ConfigMap
          env_from {
            config_map_ref {
              name = kubernetes_config_map.portfolio_config.metadata[0].name
            }
          }

          # Environment variables from Secret
          env {
            name = "SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.portfolio_secrets.metadata[0].name
                key  = "SECRET_KEY"
              }
            }
          }

          env {
            name = "API_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.portfolio_secrets.metadata[0].name
                key  = "API_KEY"
              }
            }
          }

          # Kubernetes-specific environment variables
          env {
            name = "KUBERNETES_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          env {
            name = "KUBERNETES_POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }

          env {
            name = "KUBERNETES_NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }

          # Resource limits and requests
          resources {
            requests = {
              memory = var.memory_request
              cpu    = var.cpu_request
            }
            limits = {
              memory = var.memory_limit
              cpu    = var.cpu_limit
            }
          }

          # Health checks
          liveness_probe {
            http_get {
              path = "/health"
              port = var.container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }

          # Security context
          security_context {
            allow_privilege_escalation = false
            run_as_non_root           = true
            run_as_user               = 1000
            read_only_root_filesystem = false
            
            capabilities {
              drop = ["ALL"]
            }
          }
        }

        restart_policy                   = "Always"
        termination_grace_period_seconds = 30

        security_context {
          fs_group = 1000
        }
      }
    }
  }

  depends_on = [
    kubernetes_config_map.portfolio_config,
    kubernetes_secret.portfolio_secrets
  ]
}

# ClusterIP Service
resource "kubernetes_service" "portfolio_service" {
  metadata {
    name      = "portfolio-service"
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app       = var.app_name
      component = "service"
    })
    
    annotations = merge(var.common_annotations, {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    })
  }

  spec {
    type = "ClusterIP"
    
    port {
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = var.app_name
    }
  }

  depends_on = [kubernetes_deployment.portfolio_app]
}

# NodePort Service
resource "kubernetes_service" "portfolio_nodeport" {
  metadata {
    name      = "portfolio-nodeport"
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app       = var.app_name
      component = "nodeport"
    })
  }

  spec {
    type = "NodePort"
    
    port {
      port        = var.service_port
      target_port = var.container_port
      node_port   = var.nodeport_port
      protocol    = "TCP"
      name        = "http"
    }

    selector = {
      app = var.app_name
    }
  }

  depends_on = [kubernetes_deployment.portfolio_app]
}

# Ingress
resource "kubernetes_ingress_v1" "portfolio_ingress" {
  count = var.enable_ingress ? 1 : 0

  metadata {
    name      = "portfolio-ingress"
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app       = var.app_name
      component = "ingress"
    })
    
    annotations = merge(var.common_annotations, {
      "nginx.ingress.kubernetes.io/rewrite-target"     = "/"
      "nginx.ingress.kubernetes.io/ssl-redirect"       = "false"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "false"
      "nginx.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "nginx.ingress.kubernetes.io/rate-limit"         = "100"
      "nginx.ingress.kubernetes.io/rate-limit-window"  = "1m"
    })
  }

  spec {
    ingress_class_name = var.ingress_class

    rule {
      host = var.ingress_host
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          
          backend {
            service {
              name = kubernetes_service.portfolio_service.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service.portfolio_service]
}

# Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v2" "portfolio_hpa" {
  count = var.enable_hpa ? 1 : 0

  metadata {
    name      = "portfolio-hpa"
    namespace = kubernetes_namespace.portfolio.metadata[0].name
    
    labels = merge(var.common_labels, {
      app       = var.app_name
      component = "autoscaler"
    })
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.portfolio_app.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_threshold
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_threshold
        }
      }
    }

    behavior {
      scale_down {
        stabilization_window_seconds = 300
        select_policy = "Max"   # <--- dodaj tę linię tutaj
        policy {
          type          = "Percent"
          value         = 10
          period_seconds = 60
        }
      }

      scale_up {
        stabilization_window_seconds = 60
        policy {
          type          = "Percent"
          value         = 50
          period_seconds = 60
        }
        policy {
          type          = "Pods"
          value         = 2
          period_seconds = 60
        }
        select_policy = "Max"
      }
    }
  }
}   
