# S3 bucket for F5 XC Global Log Receiver logs
resource "aws_s3_bucket" "global_logs" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_versioning" "global_logs" {
  bucket = aws_s3_bucket.global_logs.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "global_logs" {
  bucket = aws_s3_bucket.global_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "global_logs" {
  bucket = aws_s3_bucket.global_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "global_logs" {
  bucket = aws_s3_bucket.global_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy to allow F5 XC to write logs
# Note: Update the principal ARN based on F5 XC documentation for your region
resource "aws_s3_bucket_policy" "global_logs" {
  bucket = aws_s3_bucket.global_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowF5XCLogDelivery"
        Effect = "Allow"
        Principal = {
          # F5 XC Global Log Receiver service principal
          # This may need to be updated based on F5 XC documentation
          Service = "logs.amazonaws.com"
        }
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ]
        Resource = "${aws_s3_bucket.global_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}
