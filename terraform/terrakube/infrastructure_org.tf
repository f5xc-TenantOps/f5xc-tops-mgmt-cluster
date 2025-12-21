# Infrastructure organization
# Contains workspaces for AWS infrastructure, and later tfc-operator migrations

resource "terrakube_organization" "infrastructure" {
  name        = "infrastructure"
  description = "Infrastructure workspaces for observability, and future tfc-operator migrations"
}

# VCS connection for this repository
# Note: The SSH key must be manually added to Terrakube and GitHub
resource "terrakube_vcs" "github" {
  organization_id = terrakube_organization.infrastructure.id
  name            = "f5xc-tops-mgmt-cluster"
  description     = "Management cluster repository"
  vcs_type        = "GITHUB"

  # SSH connection (no inbound internet required)
  # The SSH private key is stored in Terrakube, public key as GitHub deploy key
  ssh_private_key = data.kubernetes_secret.terrakube_api.data["SSH_PRIVATE_KEY"]
}
