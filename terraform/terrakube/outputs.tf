output "infrastructure_org_id" {
  description = "ID of the Tops Cloud Infra organization"
  value       = terrakube_organization.infrastructure.id
}

output "observability_aws_workspace_id" {
  description = "ID of the observability-aws workspace"
  value       = terrakube_workspace_vcs.observability_aws.id
}

output "template_id" {
  description = "ID of the Plan and Apply template"
  value       = data.terrakube_organization_template.plan_apply.id
}
