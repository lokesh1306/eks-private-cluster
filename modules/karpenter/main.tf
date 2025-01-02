data "aws_availability_zones" "available" {}
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  partition            = data.aws_partition.current.partition
  region               = var.region
  queue_name           = "karpenter"
  create_node_iam_role = false
  node_iam_role_name   = aws_iam_role.karpenter_node_role.arn
  oidc_provider        = var.oidc_provider
  oidc_provider_arn    = var.oidc_provider_arn
}

# Fargate profile setup for EKS 
resource "aws_eks_fargate_profile" "karpenter" {
  cluster_name           = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
  fargate_profile_name   = var.karpenter_name
  pod_execution_role_arn = aws_iam_role.fargate.arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/instance" = "karpenter"
    }
  }

  tags = merge(
    {
      Name = "fargate-${var.karpenter_name}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

# Fargate profile removal after provisioning
resource "null_resource" "delete_fargate_profile" {
  provisioner "local-exec" {
    command = <<EOT
      aws eks delete-fargate-profile \
        --cluster-name ${var.cluster_name} \
        --region ${var.region} \
        --fargate-profile-name karpenter
    EOT
  }

  depends_on = [aws_eks_addon.ebs]
}

# Metrics for hpa
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  chart      = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  namespace  = "kube-system"
  version    = "3.12.2"
  depends_on = [null_resource.delete_fargate_profile]
}

# EKS Addons
resource "aws_eks_addon" "ebs" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn
  depends_on               = [time_sleep.wait_for_ebs]
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = var.cluster_name
  addon_name   = "eks-pod-identity-agent"
  depends_on   = [aws_eks_addon.vpc-cni]
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"
  depends_on   = [aws_eks_addon.eks-pod-identity-agent]
}

resource "aws_eks_addon" "vpc-cni" {
  cluster_name             = var.cluster_name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.vpc_cni.arn
  configuration_values = jsonencode({
    enableNetworkPolicy = "true"
  })
  depends_on = [time_sleep.wait_for_nodepool]
}

resource "time_sleep" "wait_for_ebs" {
  depends_on      = [aws_eks_addon.kube-proxy]
  create_duration = "30s"
}

resource "helm_release" "csi_secrets_store" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = "1.4.5"

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  set {
    name  = "enableSecretRotation"
    value = "true"
  }
  depends_on = [aws_eks_addon.ebs]
}

resource "helm_release" "secrets_store_csi_driver_provider_aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "0.3.9"
  depends_on = [helm_release.csi_secrets_store]
}

# Karpenter module
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.11"

  cluster_name = var.cluster_name

  enable_v1_permissions           = true
  create_iam_role                 = false
  enable_pod_identity             = true
  create_pod_identity_association = true

  tags       = var.common_tags
  depends_on = [aws_eks_fargate_profile.karpenter]
}

resource "helm_release" "karpenter" {
  namespace  = "kube-system"
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "1.0.1"
  wait       = true

  values = [
    <<-EOT
    serviceAccount:
      create: true
      name: karpenterirsa
      annotations:
        eks.amazonaws.com/role-arn: ${aws_iam_role.controller.arn}
    settings:
      clusterName: ${var.cluster_name}
      clusterEndpoint: ${var.cluster_endpoint}
    dnsPolicy: Default
    controller:
      resources:
        requests:
          cpu: 1
          memory: 1Gi
    tolerations:
      - key: eks.amazonaws.com/compute-type
        operator: Equal
        value: fargate
        effect: NoSchedule
    topologySpreadConstraints: []
    affinity: null
    nodeSelector: null
    EOT
  ]
  depends_on = [module.karpenter]
}

# Time for Karpenter pod provisioning
resource "time_sleep" "wait_30_seconds" {
  depends_on = [helm_release.karpenter]

  create_duration = "30s"
}

# Karpenter node class
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      metadataOptions:
        httpEndpoint: enabled
        httpProtocolIPv6: disabled
        httpPutResponseHopLimit: 2 
        httpTokens: required
      role: ${aws_iam_role.karpenter_node_role.name}
      blockDeviceMappings:
        - deviceName: /dev/sda1
          rootVolume: true
          ebs:
            volumeSize: 20Gi
            volumeType: gp2
            encrypted: true
            deleteOnTermination: true
      associatePublicIPAddress: false
      detailedMonitoring: true  
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
  YAML

  depends_on = [
    helm_release.karpenter, time_sleep.wait_30_seconds
  ]
}

# Karpenter node pool
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: app
              operator: Exists
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c"]
            - key: "karpenter.k8s.aws/instance-memory"
              operator: In
              values: ["8192"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["on-demand"]
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmpty
        consolidateAfter: 30s
  YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

# Time wait after node pool setup
resource "time_sleep" "wait_for_nodepool" {
  depends_on      = [kubectl_manifest.karpenter_node_pool]
  create_duration = "60s"
}

# EKS acess entry for Karpenter nodes
resource "aws_eks_access_entry" "eks" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node_role.arn
  type          = "EC2_LINUX"
  depends_on    = [helm_release.karpenter]
}

# Policy for EBS to access KMS
resource "aws_iam_policy" "eks_kms_policy_ebs" {
  name   = "eks-kms-policy_ebs"
  policy = data.aws_iam_policy_document.eks_kms_policy_ebs.json
}

# Policy document for EBS to access KMS
data "aws_iam_policy_document" "eks_kms_policy_ebs" {
  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey", "kms:CreateGrant"]
    resources = ["*"]
  }
}

# EBS policy for KMS access attachment
resource "aws_iam_role_policy_attachment" "eks_kms_policy_attachment_ebs" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = aws_iam_policy.eks_kms_policy_ebs.arn
}


data "aws_iam_policy" "node_management_group_policy" {
  for_each = toset(["AmazonEKSWorkerNodePolicy", "AmazonEC2ContainerRegistryReadOnly", "AmazonEKS_CNI_Policy", "AmazonEBSCSIDriverPolicy"])
  name     = each.value
}

resource "aws_iam_role_policy_attachment" "eks_node_role_policy_attachment" {
  for_each   = data.aws_iam_policy.node_management_group_policy
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = each.value.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role" "karpenter_node_role" {
  name = "KarpenterNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "karpenter_node_policy" {
  name        = "KarpenterNodeRole"
  description = "IAM policy for EKS Cluster Autoscaler"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "autoscaling:*",
          "ec2:*",
          "cloudwatch:*",
          "iam:*",
          "sns:*",
          "elasticloadbalancing:*",
          "pricing:*"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_policy_attach" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = aws_iam_policy.karpenter_node_policy.arn
}

resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role" "fargate" {
  name = "eks-fargate"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate.name
}

data "aws_iam_policy_document" "ebs_csi_irsa" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_irsa.json
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi.name
}

data "aws_iam_policy_document" "vpc_cni_irsa" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    effect = "Allow"
  }
}

resource "aws_iam_role" "vpc_cni" {
  name               = "vpc-cni"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_irsa.json
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCCNIPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni.name
}

resource "aws_iam_role" "controller" {
  name                  = "KarpenterController"
  assume_role_policy    = data.aws_iam_policy_document.controller_assume_role.json
  force_detach_policies = true

}

data "aws_iam_policy_document" "controller_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:kube-system:karpenterirsa"]
    }
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = ["system:serviceaccount:s3:kubectl-access"]
    }
  }
}

data "aws_iam_policy_document" "controller" {

  statement {
    sid = "AllowScopedEC2InstanceActions"
    resources = [
      "*"
    ]

    actions = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "controller" {

  name   = "KarpenterController"
  policy = data.aws_iam_policy_document.controller.json

}

resource "aws_iam_role_policy_attachment" "controller" {


  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller.arn
}