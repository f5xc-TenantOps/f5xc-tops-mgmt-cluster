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

output "vector_secret_name" {
  description = "Name of the Kubernetes secret containing Vector AWS credentials"
  value       = kubernetes_secret.vector_aws_credentials.metadata[0].name
}

output "vector_secret_namespace" {
  description = "Namespace of the Kubernetes secret containing Vector AWS credentials"
  value       = kubernetes_secret.vector_aws_credentials.metadata[0].namespace
}
