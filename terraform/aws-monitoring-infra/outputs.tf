output "bucket_name" {
  description = "Name of the S3 bucket for Global Log Receiver logs"
  value       = aws_s3_bucket.global_logs.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.global_logs.arn
}

output "bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.global_logs.region
}

output "vector_user_arn" {
  description = "ARN of the IAM user for Vector"
  value       = aws_iam_user.vector.arn
}

output "vector_access_key_id" {
  description = "Access key ID for Vector (store in observability-bootstrap.yml)"
  value       = aws_iam_access_key.vector.id
}

output "vector_secret_access_key" {
  description = "Secret access key for Vector (store in observability-bootstrap.yml)"
  value       = aws_iam_access_key.vector.secret
  sensitive   = true
}
