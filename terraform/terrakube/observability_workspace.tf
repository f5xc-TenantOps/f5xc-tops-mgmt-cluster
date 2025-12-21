# Observability AWS infrastructure workspace
# Creates S3 bucket and IAM user for Vector log ingestion

resource "terrakube_workspace_vcs" "observability_aws" {
  organization_id = terrakube_organization.infrastructure.id
  name            = "observability-aws"
  description     = "AWS infrastructure for observability stack (S3 bucket, IAM for Vector)"

  # VCS configuration
  repository = "git@github.com:${var.github_repo}.git"
  branch     = "main"
  folder     = "terraform/aws-monitoring-infra"

  # Use SSH key for private repo access
  vcs_id = terrakube_ssh.github_deploy_key.id

  # Terraform configuration
  iac_type    = "terraform"
  iac_version = "1.6.0"

  # Execution settings
  execution_mode = "remote"
  template_id    = terrakube_organization_template.plan_apply.id
}

# Inject AWS credentials as workspace environment variables
resource "terrakube_workspace_variable" "aws_access_key" {
  workspace_id = terrakube_workspace_vcs.observability_aws.id
  key          = "AWS_ACCESS_KEY_ID"
  value        = data.kubernetes_secret.aws_credentials.data["AWS_ACCESS_KEY_ID"]
  category     = "ENV"
  sensitive    = true
  hcl          = false
  description  = "AWS access key for creating S3 and IAM resources"
}

resource "terrakube_workspace_variable" "aws_secret_key" {
  workspace_id = terrakube_workspace_vcs.observability_aws.id
  key          = "AWS_SECRET_ACCESS_KEY"
  value        = data.kubernetes_secret.aws_credentials.data["AWS_SECRET_ACCESS_KEY"]
  category     = "ENV"
  sensitive    = true
  hcl          = false
  description  = "AWS secret key for creating S3 and IAM resources"
}

# Set AWS region as terraform variable
resource "terrakube_workspace_variable" "aws_region" {
  workspace_id = terrakube_workspace_vcs.observability_aws.id
  key          = "aws_region"
  value        = lookup(data.kubernetes_secret.aws_credentials.data, "AWS_REGION", "us-east-1")
  category     = "TERRAFORM"
  sensitive    = false
  hcl          = false
  description  = "AWS region for resources"
}
