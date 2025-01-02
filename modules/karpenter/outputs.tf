output "cluster_name_fargate" {
  value = aws_eks_fargate_profile.karpenter.cluster_name
}

output "delete_fargate_profile_complete" {
  value = null_resource.delete_fargate_profile.id
}