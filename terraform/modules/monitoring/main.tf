resource "helm_release" "monitoring" {
  name             = "monitoring"
  namespace        = kubernetes_namespace_v1.monitoring_ns.metadata[0].name
  create_namespace = true

  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.monitoring_chart_version

  set = [
    {
      name  = "grafana.env.GF_SECURITY_CSRF_TRUSTED_ORIGINS"
      value = "${var.grafana_port}-${var.grafana_csrf_trusted_origins}"
      type  = "string"
    }
  ]

  values = [
    file("${path.module}/../../../helm/monitoring-values.yaml"),

    yamlencode({
      grafana = {
        sidecar = {
          dashboards = {
            enabled         = true
            label           = "grafana_dashboard"
            labelValue      = "hoofkhanh"
            searchNamespace = "ALL"
          }
        }
      }
    })
  ]

  depends_on = [kubernetes_secret_v1.alertmanager_smtp, kubernetes_config_map_v1.grafana_dashboard]
}

resource "kubernetes_secret_v1" "alertmanager_smtp" {
  metadata {
    name      = "secret-monitoring"
    namespace = kubernetes_namespace_v1.monitoring_ns.metadata[0].name
  }

  type = "Opaque"

  data = {
    "smtp-username" = var.smtp_username
    "smtp-password" = var.smtp_password
  }
}

resource "kubernetes_namespace_v1" "monitoring_ns" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_config_map_v1" "grafana_dashboard" {
  metadata {
    name      = "metrics-dashboard"
    namespace = "monitoring"

    labels = {
      grafana_dashboard = "hoofkhanh"
    }
  }

  data = {
    "golden-signals.json" = file("${path.module}/dashboards/golden-signals.json")
  }
}