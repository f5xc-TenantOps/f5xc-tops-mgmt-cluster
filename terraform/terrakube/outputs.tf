output "infrastructure_org_id" {
  description = "ID of the infrastructure organization"
  value       = terrakube_organization.infrastructure.id
}

output "observability_aws_workspace_id" {
  description = "ID of the observability-aws workspace"
  value       = terrakube_workspace_vcs.observability_aws.id
}

output "ssh_key_id" {
  description = "ID of the SSH key for repository access"
  value       = terrakube_ssh.github_deploy_key.id
}

output "template_id" {
  description = "ID of the Plan and Apply template"
  value       = terrakube_organization_template.plan_apply.id
}
