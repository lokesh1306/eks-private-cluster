data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# EKS Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31"

  cluster_name    = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
  cluster_version = var.cluster_version

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_id                   = var.vpc_id
  subnet_ids               = var.private_subnet_ids
  control_plane_subnet_ids = var.private_subnet_ids
  node_security_group_tags = merge(var.common_tags, {
    "karpenter.sh/discovery" = "${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
  })
  tags = merge(
    {
      Name = "eks-${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
    },
    var.common_tags
  )
}

# Role for EKS access
resource "aws_iam_role_policy" "eks_access" {
  name = "eks-access-policy-${var.common_tags["Project"]}-${var.common_tags["Environment"]}"
  role = var.remote_state.outputs.ssm_role_name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "eks:ListClusters",
          "eks:DescribeCluster"
        ],
        Resource = "arn:aws:eks:${var.region}:${data.aws_caller_identity.current.account_id}:cluster/${module.eks.cluster_name}-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
      }
    ]
  })
}

# EKS access for SSM
resource "aws_eks_access_entry" "eks" {
  cluster_name  = module.eks.cluster_name
  principal_arn = var.remote_state.outputs.ssm_role_arn
  type          = "STANDARD"
}

# EKS SSM access policy association
resource "aws_eks_access_policy_association" "eks" {
  cluster_name  = module.eks.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = var.remote_state.outputs.ssm_role_arn

  access_scope {
    type = "cluster"
  }
}

# SSM Egress SG for EKS
resource "aws_security_group_rule" "ec2_egress" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = var.remote_state.outputs.ec2_sg
  source_security_group_id = module.eks.cluster_primary_security_group_id
}

# EKS Ingress SG for SSM
resource "aws_security_group_rule" "eks_ingress" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = -1
  security_group_id        = module.eks.cluster_primary_security_group_id
  source_security_group_id = var.remote_state.outputs.ec2_sg
}