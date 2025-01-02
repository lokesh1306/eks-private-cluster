output "cluster_name_fargate" {
  value = aws_eks_fargate_profile.karpenter.cluster_name
}