resource "random_uuid" "bucket1" {}
resource "random_uuid" "bucket2" {}

resource "aws_s3_bucket" "bucket1" {
  bucket = "s3-bucket2-${var.common_tags["Environment"]}-${var.common_tags["Project"]}-${random_uuid.bucket1.result}"
}

resource "aws_s3_bucket_versioning" "bucket1_versioning" {
  bucket = aws_s3_bucket.bucket1.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "s3-bucket2-${var.common_tags["Environment"]}-${var.common_tags["Project"]}-${random_uuid.bucket2.result}"
}

resource "aws_s3_bucket_versioning" "bucket2_versioning" {
  bucket = aws_s3_bucket.bucket2.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_policy" "bucket1_policy" {
  name        = "s3-bucket1-policy-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  description = "Policy to allow listing objects in Bucket 1"

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

resource "aws_iam_policy" "bucket2_policy" {
  name        = "s3-bucket2-policy-${var.common_tags["Environment"]}-${var.common_tags["Project"]}"
  description = "Policy to allow listing, reading, and writing to Bucket 2"

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
          "s3:PutObjectVersion",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ],
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.bucket2.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.bucket2.bucket}/*",
        ],
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "attach_bucket1_policy" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.bucket1_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_bucket2_policy" {
  role       = var.app_role_name
  policy_arn = aws_iam_policy.bucket2_policy.arn
}