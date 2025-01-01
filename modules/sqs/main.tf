data "aws_caller_identity" "current" {}

resource "aws_sqs_queue" "sqs_queue" {
  name                       = "sqs-queue-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  delay_seconds              = var.delay_seconds
  fifo_queue                 = var.fifo_queue

  tags = merge(
    {
      Name = "sqs-queue-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
    },
    var.common_tags
  )
}

resource "aws_sqs_queue_policy" "sqs_queue_policy" {
  queue_url = aws_sqs_queue.sqs_queue.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAppAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_role_name}"
        },
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
        ],
        Resource = aws_sqs_queue.sqs_queue.arn
      },
    ]
  })
}

resource "aws_iam_policy" "sqs_eks_policy" {
  name        = "sqs-eks-policy-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  description = "Allow the app to consume messages from the private SQS queue"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowQueueAccess",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
        ],
        Resource = aws_sqs_queue.sqs_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_sqs_policy" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.sqs_eks_policy.arn
}