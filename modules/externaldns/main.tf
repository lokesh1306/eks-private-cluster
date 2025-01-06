data "aws_secretsmanager_secret" "cloudflare" {
  name = "${var.common_tags["Environment"]}/cloudflare"
}

data "aws_secretsmanager_secret_version" "cloudflare" {
  secret_id = data.aws_secretsmanager_secret.cloudflare.id
}

resource "kubernetes_secret" "cloudflare_api_key" {
  metadata {
    name      = "cloudflare-api-key-${var.common_tags["Project"]}"
    namespace = "kube-system"
  }

  data = {
    apiKey = jsondecode(data.aws_secretsmanager_secret_version.cloudflare.secret_string)["key"]
    email  = var.cf_email
  }

  type = "Opaque"
}

resource "helm_release" "external_dns" {
  name       = "external-dns-${var.common_tags["Project"]}"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  set {
    name  = "provider.name"
    value = "cloudflare"
  }
  set {
    name  = "interval"
    value = "1m"
  }
  set {
    name  = "env[0].name"
    value = "CF_API_KEY"
  }

  set {
    name  = "env[0].valueFrom.secretKeyRef.name"
    value = kubernetes_secret.cloudflare_api_key.metadata[0].name
  }

  set {
    name  = "env[0].valueFrom.secretKeyRef.key"
    value = "apiKey"
  }

  set {
    name  = "env[1].name"
    value = "CF_API_EMAIL"
  }

  set {
    name  = "env[1].valueFrom.secretKeyRef.name"
    value = kubernetes_secret.cloudflare_api_key.metadata[0].name
  }

  set {
    name  = "env[1].valueFrom.secretKeyRef.key"
    value = "email"
  }

  set {
    name  = "domainFilters[0]"
    value = var.cf_domain
  }

  set {
    name  = "txtOwnerId"
    value = "external-dns"
  }

  set {
    name  = "policy"
    value = "sync"
  }

  set {
    name  = "rbac.create"
    value = "true"
  }
  set {
    name  = "timestamp"
    value = timestamp()
  }

  depends_on = [var.delete_fargate_profile_dependency]
}