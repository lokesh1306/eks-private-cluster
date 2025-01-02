data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_partition" "current" {}

data "aws_rds_cluster" "mysql_cluster" {
  cluster_identifier = var.mysql_cluster_id
}

ephemeral "aws_secretsmanager_secret_version" "mysql" {
  secret_id = data.aws_rds_cluster.mysql_cluster.master_user_secret[0].secret_arn
}

locals {
  mysql_credentials = jsondecode(ephemeral.aws_secretsmanager_secret_version.mysql.secret_string)
}

# k8 namespace for app
resource "kubernetes_namespace" "app" {
  metadata {
    name   = "app"
    labels = var.common_tags
  }
}

# k8 SA for app
resource "kubernetes_service_account" "app-sa" {
  metadata {
    name      = "sa-${var.common_tags["Project"]}"
    namespace = kubernetes_namespace.app.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.app.arn}"
    }
  }
}

# k8 app role
resource "aws_iam_role" "app" {
  name               = "app-role-${var.common_tags["Project"]}"
  assume_role_policy = data.aws_iam_policy_document.app.json

  tags = merge(
    {
      Name    = "app-role-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
      Cluster = var.cluster_name_fargate
    },
    var.common_tags
  )
}

# k8 app role trust policy
data "aws_iam_policy_document" "app" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_provider}:sub"
      values   = ["system:serviceaccount:${kubernetes_namespace.app.metadata[0].name}:sa-${var.common_tags["Project"]}"]
    }

    effect = "Allow"
  }
}

# k8 app helm chart
resource "helm_release" "app" {
  name       = var.release_name
  repository = "https://${var.github_owner}.github.io/${var.repo_name}/charts"
  chart      = var.chart_name
  version    = var.chart_version
  namespace  = kubernetes_namespace.app.metadata[0].name

  set {
    name  = "timestamp"
    value = timestamp()
  }

  depends_on = [var.delete_fargate_profile_dependency]
}

# App access to DB
resource "aws_security_group_rule" "mysql_ingress_eks" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  security_group_id = var.mysql_sg_id
  cidr_blocks       = [var.vpc_cidr]
}

# App auth to RDS
resource "aws_iam_policy" "rds_connect_policy" {
  name = "rds-eks-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds-db:connect"
        Resource = "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${var.cluster_resource_id}/${var.app_mysql_user}"
      }
    ]
  })
}

# App RDS auth attachment
resource "aws_iam_role_policy_attachment" "attach_rds_connect_policy" {
  policy_arn = aws_iam_policy.rds_connect_policy.arn
  role       = aws_iam_role.app.name
}