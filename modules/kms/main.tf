data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_kms_key" "eks" {
  description             = "Key for EKS Cluster"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:CreateKey",
      "kms:DescribeKey",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:ListKeyPolicies",
      "kms:GetKeyPolicy",
      "kms:PutKeyPolicy"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Allow EKS to Use Key"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
    actions = [
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant",
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.eks.id}"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["eks.${data.aws_region.current.name}.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  # New statement to allow user Lokesh to access key rotation status
  statement {
    sid    = "Allow User Lokesh to GetKeyRotationStatus"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Lokesh"]
    }
    actions = [
      "kms:GetKeyRotationStatus",
      "kms:DescribeKey"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/${aws_kms_key.eks.id}"]
  }
}

resource "aws_kms_key_policy" "eks_policy" {
  key_id = aws_kms_key.eks.id
  policy = data.aws_iam_policy_document.kms_key_policy.json
}