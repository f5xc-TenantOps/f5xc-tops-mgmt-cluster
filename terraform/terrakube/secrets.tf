# Read secrets from Kubernetes cluster
# These are applied via bootstrap secret files (gitignored)

# Terrakube API token (from terrakube-bootstrap.yml)
data "kubernetes_secret" "terrakube_api" {
  metadata {
    name      = "terrakube-api-secrets"
    namespace = "terrakube"
  }
}

# AWS credentials for observability workspace (from observability-bootstrap.yml)
# Note: These are the credentials for RUNNING terraform, not the Vector credentials
data "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = "observability"
  }
}
