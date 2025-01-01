data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31"

  cluster_name    = "${var.cluster_name}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  cluster_version = var.cluster_version

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids
  node_security_group_tags = merge(var.common_tags, {
    "karpenter.sh/discovery" = "${var.cluster_name}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  })
  tags = merge(
    {
      Name = "eks-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

data "aws_iam_role" "ssm_role" {
  name = "EC2-SSM-Access-Role"
}

resource "aws_iam_role_policy" "eks_access" {
  name = "eks-access-policy"
  role = data.aws_iam_role.ssm_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster"
        ],
        Resource = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
      }
    ]
  })
}

resource "aws_eks_access_entry" "eks" {
  cluster_name  = module.eks.cluster_name
  principal_arn = data.aws_iam_role.ssm_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = data.aws_iam_role.ssm_role.arn

  access_scope {
    type = "cluster"
  }
}

resource "aws_security_group_rule" "ec2_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = var.remote_state.outputs.ec2_sg
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

resource "aws_security_group_rule" "eks_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = var.remote_state.outputs.ec2_sg
}