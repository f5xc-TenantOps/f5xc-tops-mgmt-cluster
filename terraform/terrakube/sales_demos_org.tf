# Sales Demos organization
# Contains workspaces for sales demonstrations

resource "terrakube_organization" "sales_demos" {
  name           = "Sales Demos"
  description    = "Workspaces for sales demonstrations"
  execution_mode = "remote"
}

# Grant admin team permissions to manage resources in this organization
resource "terrakube_team" "sales_demos_admin" {
  organization_id  = terrakube_organization.sales_demos.id
  name             = "f5xc-TenantOps:tenantops-admin"
  manage_workspace = true
  manage_module    = true
  manage_provider  = true
  manage_vcs       = true
  manage_template  = true
}

# Read-only access for tenantops-ro team
resource "terrakube_team" "sales_demos_readonly" {
  organization_id  = terrakube_organization.sales_demos.id
  name             = "f5xc-TenantOps:tenantops-ro"
  manage_workspace = false
  manage_module    = false
  manage_provider  = false
  manage_vcs       = false
  manage_template  = false
}
