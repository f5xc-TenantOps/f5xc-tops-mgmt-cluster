variable "terrakube_endpoint" {
  description = "Terrakube API endpoint"
  type        = string
  default     = "https://terrakube-api.tops.k11s.io"
}

variable "terrakube_org_name" {
  description = "Name of the bootstrap Terrakube org (where this workspace runs)"
  type        = string
  default     = "terrakube"
}

variable "github_repo" {
  description = "GitHub repository for VCS connection"
  type        = string
  default     = "f5xc-TenantOps/f5xc-tops-mgmt-cluster"
}
