# Infrastructure organization
# Contains workspaces for AWS infrastructure, and later tfc-operator migrations

resource "terrakube_organization" "infrastructure" {
  name           = "infrastructure"
  description    = "Infrastructure workspaces for observability, and future tfc-operator migrations"
  execution_mode = "remote"
}

# Grant team permissions to manage resources in this organization
resource "terrakube_team" "admin_team" {
  organization_id  = terrakube_organization.infrastructure.id
  name             = "f5xc-TenantOps:tenantops-admin"
  manage_workspace = true
  manage_module    = true
  manage_provider  = true
  manage_vcs       = true
  manage_template  = true
}

# Read-only access for tenantops-ro team
# Users can view resources but cannot create/modify/delete
resource "terrakube_team" "readonly_team" {
  organization_id  = terrakube_organization.infrastructure.id
  name             = "f5xc-TenantOps:tenantops-ro"
  manage_workspace = false
  manage_module    = false
  manage_provider  = false
  manage_vcs       = false
  manage_template  = false
}

# SSH key for private repository access
resource "terrakube_ssh" "github_deploy_key" {
  organization_id = terrakube_organization.infrastructure.id
  name            = "github-deploy-key"
  description     = "Deploy key for f5xc-tops-mgmt-cluster repository"
  private_key     = data.kubernetes_secret.terrakube_api.data["SSH_PRIVATE_KEY"]
  ssh_type        = "rsa"

  depends_on = [terrakube_team.admin_team]
}

# Default template for Plan and Apply workflow
resource "terrakube_organization_template" "plan_apply" {
  name            = "Plan and Apply"
  organization_id = terrakube_organization.infrastructure.id
  description     = "Standard Terraform plan and apply workflow"
  version         = "1.0.0"
  content         = <<-EOF
flow:
  - type: "terraformPlan"
    name: "Plan"
    step: 100
  - type: "terraformApply"
    name: "Apply"
    step: 200
EOF

  depends_on = [terrakube_team.admin_team]
}

# Plan with Approval template for scheduled drift detection
resource "terrakube_organization_template" "plan_with_approval" {
  name            = "Plan with Approval"
  organization_id = terrakube_organization.infrastructure.id
  description     = "Plan followed by approval gate before apply"
  version         = "1.0.0"
  content         = <<-EOF
flow:
  - type: "terraformPlan"
    name: "Plan"
    step: 100
  - type: "approval"
    name: "Approve Apply"
    step: 150
    team: "f5xc-TenantOps:tenantops-admin"
  - type: "terraformApply"
    name: "Apply"
    step: 200
EOF

  depends_on = [terrakube_team.admin_team]
}
