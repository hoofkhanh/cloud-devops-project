resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  version = var.argocd_chart_version

  values = [
    file("${path.module}/argocd-values.yaml")
  ]
}