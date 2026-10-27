resource "helm_release" "monitoring" {
  name             = "monitoring"
  namespace        = "monitoring"
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
}