output "infrastructure_org_id" {
  description = "ID of the infrastructure organization"
  value       = terrakube_organization.infrastructure.id
}

output "observability_aws_workspace_id" {
  description = "ID of the observability-aws workspace"
  value       = terrakube_workspace.observability_aws.id
}

output "vcs_connection_id" {
  description = "ID of the VCS connection"
  value       = terrakube_vcs.github.id
}
