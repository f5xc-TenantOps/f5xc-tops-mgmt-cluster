# IAM user for Vector to read logs from S3
resource "aws_iam_user" "vector" {
  name = var.vector_user_name
  path = "/service-accounts/"
}

# Access key for Vector (static credentials)
resource "aws_iam_access_key" "vector" {
  user = aws_iam_user.vector.name
}

# Policy allowing Vector to read from the log bucket
resource "aws_iam_user_policy" "vector_s3_read" {
  name = "vector-s3-log-read"
  user = aws_iam_user.vector.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.global_logs.arn
      },
      {
        Sid    = "ReadObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.global_logs.arn}/*"
      }
    ]
  })
}
