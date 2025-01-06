resource "random_uuid" "bucket1" {}
resource "random_uuid" "bucket2" {}
data "aws_caller_identity" "current" {}

# S3 bucket1
resource "aws_s3_bucket" "bucket1" {
  bucket        = "s3-bucket1-${var.common_tags["Environment"]}-${var.common_tags["Project"]}-${random_uuid.bucket1.result}"
  force_destroy = true
}

# S3 bucket1 versioning 
resource "aws_s3_bucket_versioning" "bucket1_versioning" {
  bucket = aws_s3_bucket.bucket1.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket2
resource "aws_s3_bucket" "bucket2" {
  bucket        = "s3-bucket2-${var.common_tags["Environment"]}-${var.common_tags["Project"]}-${random_uuid.bucket2.result}"
  force_destroy = true
}

# S3 bucket2 versioning 
resource "aws_s3_bucket_versioning" "bucket2_versioning" {
  bucket = aws_s3_bucket.bucket2.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket1 list only policy 
resource "aws_iam_policy" "bucket1_policy" {
  name = "s3-bucket1-policy-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ListBucket1",
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions"
        ],
        Resource = "arn:aws:s3:::${aws_s3_bucket.bucket1.bucket}",
      },
    ],
  })
}

# S3 bucket2 policy to allow read/write only, no list
resource "aws_iam_policy" "bucket2_policy" {
  name = "s3-bucket2-policy-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ListReadWriteBucket2",
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:PutObjectVersion"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.bucket2.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bucket2.bucket}/*",
        ],
      },
    ],
  })
}

# S3 bucket1 policy attachment to existing app role
resource "aws_iam_role_policy_attachment" "attach_bucket1_policy" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.bucket1_policy.arn
}

# S3 bucket2 policy attachment to existing app role
resource "aws_iam_role_policy_attachment" "attach_bucket2_policy" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.bucket2_policy.arn
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_subnet_route_tables
  tags = merge(
    {
      Name = "s3-endpoint-${var.common_tags["Environment"]}"
    },
    var.common_tags
  )
}

# # Bucket polciy to restrict access to VPCe/caller
# resource "aws_s3_bucket_policy" "bucket2" {
#   bucket = aws_s3_bucket.bucket2.id

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid       = "VPCe",
#         Effect    = "Deny",
#         Principal = "*",
#         Action    = "s3:*",
#         Resource  = [
#           "arn:aws:s3:::${aws_s3_bucket.bucket2.id}",
#           "arn:aws:s3:::${aws_s3_bucket.bucket2.id}/*"
#         ],
#         Condition = {
#           StringNotEquals = {
#             "aws:sourceVpce" = aws_vpc_endpoint.s3.id
#           }
#         }
#       },
#       {
#         Sid       = "Caller",
#         Effect    = "Deny",
#         Principal = "*",
#         Action    = "s3:*",
#         Resource  = [
#           "arn:aws:s3:::${aws_s3_bucket.bucket2.id}",
#           "arn:aws:s3:::${aws_s3_bucket.bucket2.id}/*"
#         ],
#         Condition = {
#           StringNotLike = {
#             "aws:userid" = "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/EC2-SSM-Access-Role/*"
#           }
#         }
#       }
#     ]
#   })
# }
