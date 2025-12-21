variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name for the S3 bucket that receives F5 XC Global Log Receiver logs"
  type        = string
  default     = "f5xc-tops-global-logs"
}

variable "retention_days" {
  description = "Number of days to retain logs in S3"
  type        = number
  default     = 30
}

variable "vector_user_name" {
  description = "Name for the IAM user that Vector uses to read from S3"
  type        = string
  default     = "vector-log-reader"
}
