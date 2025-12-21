# Create Kubernetes secret for Vector to access S3
# This secret is created by terraform and should NOT be managed by ArgoCD
resource "kubernetes_secret" "vector_aws_credentials" {
  metadata {
    name      = "vector-aws-credentials"
    namespace = "observability"

    # Annotations to prevent ArgoCD from managing this secret
    annotations = {
      "argocd.argoproj.io/compare-options" = "IgnoreExtraneous"
      "argocd.argoproj.io/sync-options"    = "Prune=false"
    }

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/component"  = "vector"
    }
  }

  data = {
    AWS_ACCESS_KEY_ID     = aws_iam_access_key.vector.id
    AWS_SECRET_ACCESS_KEY = aws_iam_access_key.vector.secret
    AWS_REGION            = var.aws_region
    S3_BUCKET_NAME        = aws_s3_bucket.global_logs.id
  }

  type = "Opaque"
}
