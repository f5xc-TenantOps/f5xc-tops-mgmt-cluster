# Observability Stack & Terrakube Self-Management Plan

## Overview

This plan implements a comprehensive observability stack and establishes Terrakube self-management capabilities.

**Design Principles:**
- No inbound internet connectivity required (pull-based architectures)
- Modular ArgoCD Applications for each component
- Bootstrap secrets pattern (gitignored, manually applied)
- 30-day or 30GB cap on all collected data (whichever is reached first)

---

## Part 0: Bootstrap Documentation Update

### Current State
The existing `bootstrap.md` is microk8s-specific. It needs to be generalized for any Kubernetes cluster.

### New Bootstrap Documentation Structure

```markdown
# Bootstrap

## Cluster Prerequisites

### Required
- Kubernetes cluster (any distribution)
- ArgoCD installed and accessible

### Recommended Components
- **Ingress Controller** (e.g., nginx-ingress, traefik)
  - Required for external access to UIs (ArgoCD, Terrakube, Grafana)
- **cert-manager**
  - Required for automatic TLS certificate management
  - Configure ClusterIssuer for your domain

### Namespaces (Create Before ArgoCD Apps)
All namespaces are defined in `bootstrap-ns.yml`. Apply first:

kubectl apply -f bootstrap-ns.yml

This creates: argocd, terrakube, observability, tfc-operator-system

### Bootstrap Secrets
Bootstrap secrets are organized by project, with one file per component:

| File | Namespace | Secrets |
|------|-----------|---------|
| `tfc-bootstrap.yml` | `tfc-operator-system` | terraformrc, tenant-tokens, workspacesecrets |
| `terrakube-bootstrap.yml` | `terrakube` | terrakube-api-secrets |
| `observability-bootstrap.yml` | `observability` | aws-credentials, f5xc-tenant-credentials, grafana-admin |

Each has a `.example` template committed to the repo. Copy and fill in values:

cp tfc-bootstrap.yml.example tfc-bootstrap.yml
cp terrakube-bootstrap.yml.example terrakube-bootstrap.yml
cp observability-bootstrap.yml.example observability-bootstrap.yml
# Edit each file with real values
kubectl apply -f tfc-bootstrap.yml -f terrakube-bootstrap.yml -f observability-bootstrap.yml

### ArgoCD Initial Setup
1. Apply namespaces: `kubectl apply -f bootstrap-ns.yml`
2. Apply bootstrap secrets: `kubectl apply -f tfc-bootstrap.yml -f terrakube-bootstrap.yml -f observability-bootstrap.yml`
3. Configure ArgoCD (replace config, apply ingress)
4. Apply the root ArgoCD app: `kubectl apply -f argocd/argocd-app.yml`
5. ArgoCD will sync all other applications
```

---

## Part 1: Observability Stack

### Namespace & ArgoCD Project
- **Namespace:** `observability`
- **ArgoCD Project:** `observability`

### Components

| Component | Helm Chart | Purpose |
|-----------|------------|---------|
| Prometheus | `prometheus-community/kube-prometheus-stack` | Metrics collection & alerting |
| Grafana | `grafana/grafana` | Visualization & dashboards |
| Loki | `grafana/loki` | Log aggregation |
| Vector | `vector/vector` | Log shipping from S3 to Loki |
| f5xc-prom-exporter | Custom manifests | F5 XC metrics (3 tenants initially) |

### Data Sources

1. **Kubernetes Cluster** - Native metrics via kube-prometheus-stack
2. **ArgoCD** - Metrics endpoint scraped by Prometheus
3. **AWS Lambdas** - CloudWatch metrics via YACE or similar
4. **F5 XC Global Log Receivers** - Logs pulled from S3 by Vector → Loki
5. **F5 XC Prometheus Exporter** - Custom exporter (one container per tenant)

### Directory Structure

```
observability/
├── values-prometheus.yml          # kube-prometheus-stack values
├── values-grafana.yml             # Grafana values
├── values-loki.yml                # Loki values
├── values-vector.yml              # Vector values
└── f5xc-exporter/
    ├── deployment.yml             # 3 containers (one per tenant)
    ├── service.yml                # Metrics endpoint for Prometheus
    └── servicemonitor.yml         # Prometheus ServiceMonitor
```

### ArgoCD Applications

Each component gets its own ArgoCD Application in `argocd/`:

```
argocd/
├── observability-project.yml      # ArgoCD Project definition
├── prometheus-app.yml             # kube-prometheus-stack
├── grafana-app.yml                # Grafana
├── loki-app.yml                   # Loki
├── vector-app.yml                 # Vector
└── f5xc-exporter-app.yml          # Custom exporter
```

### Retention & Storage Limits

| Component | Retention | Storage Limit |
|-----------|-----------|---------------|
| Prometheus | 30 days | 30GB PVC |
| Loki | 30 days | 30GB PVC |

### Observability Secrets

See `observability-bootstrap.yml.example` for the template. Secrets required:

| Secret Name | Keys | Used By |
|-------------|------|---------|
| `aws-credentials` | AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION, S3_BUCKET_NAME | Vector (S3 log pull) |
| `f5xc-tenant-credentials` | TENANT{1,2,3}_NAME, TENANT{1,2,3}_API_URL, TENANT{1,2,3}_API_TOKEN | f5xc-prom-exporter |
| `grafana-admin` | admin-user, admin-password | Grafana |

---

## Part 2: AWS Monitoring Infrastructure

### Terraform Project

```
terraform/
└── aws-monitoring-infra/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── s3.tf                      # S3 bucket for Global Log Receivers
    ├── iam.tf                     # IAM user/policy for Vector
    └── providers.tf
```

### Resources Created

1. **S3 Bucket** - Receives logs from F5 XC Global Log Receivers
   - Lifecycle policy: 30-day expiration
   - Bucket policy for F5 XC to write logs

2. **IAM User** - For Vector to pull logs
   - Policy: `s3:GetObject`, `s3:ListBucket` on the log bucket
   - Static credentials (stored in observability-bootstrap.yml)

### Manual Step After Terraform Apply

Configure F5 XC Global Log Receivers to write to the created S3 bucket (manual via F5 XC console).

---

## Part 3: Terrakube Self-Management

### Terraform Project

```
terraform/
└── terrakube-workspaces/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf               # terrakube + kubernetes providers
    ├── workspaces.tf              # Workspace definitions
    └── vcs.tf                     # VCS connection (SSH)
```

### Providers

```hcl
terraform {
  required_providers {
    terrakube = {
      source  = "AzBuilder/terrakube"
      version = "~> 1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  # Uses in-cluster config when running in Terrakube
  config_path = "~/.kube/config"  # For local dev
}

provider "terrakube" {
  endpoint = "https://terrakube-api.tops.k11s.io"
  token    = var.terrakube_token
}
```

### Workspaces Managed

| Workspace | Repository | Purpose |
|-----------|------------|---------|
| `terrakube-self` | `f5xc-TenantOps/f5xc-tops-mgmt-cluster` (path: `terraform/terrakube-workspaces`) | Manages Terrakube workspaces, variables, VCS connections |
| `aws-monitoring-infra` | `f5xc-TenantOps/f5xc-tops-mgmt-cluster` (path: `terraform/aws-monitoring-infra`) | S3 bucket, IAM for observability |

### VCS Connection

- **Method:** SSH key (no inbound internet required)
- **Polling:** Periodic (configured in Terrakube)
- **Repository:** `git@github.com:f5xc-TenantOps/f5xc-tops-mgmt-cluster.git`

### Kubernetes Provider Usage

The kubernetes provider pulls secrets from the cluster into Terrakube workspace variables:

```hcl
data "kubernetes_secret" "aws_credentials" {
  metadata {
    name      = "aws-credentials"
    namespace = "observability"
  }
}

resource "terrakube_workspace_variable" "aws_access_key" {
  workspace_id = terrakube_workspace.aws_monitoring.id
  key          = "AWS_ACCESS_KEY_ID"
  value        = data.kubernetes_secret.aws_credentials.data["AWS_ACCESS_KEY_ID"]
  category     = "ENV"
  sensitive    = true
}
```

### Terrakube Secrets

See `terrakube-bootstrap.yml.example` for the template. Secrets required:

| Secret Name | Keys | Used By |
|-------------|------|---------|
| `terrakube-api-secrets` | TERRAKUBE_TOKEN, SSH_PRIVATE_KEY | Terrakube self-management |

---

## Part 4: ArgoCD Configuration

### Update `.gitignore`

Keep the existing bootstrap file entries and add terraform + observability:

```diff
  tfc-bootstrap.yml
  terrakube-bootstrap.yml
+ observability-bootstrap.yml
+
+ # Terraform managed by Terrakube
+ terraform/
```

### ArgoCD Project Definition (`argocd/observability-project.yml`)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: observability
  namespace: argocd
spec:
  description: Observability stack components
  sourceRepos:
    - https://prometheus-community.github.io/helm-charts
    - https://grafana.github.io/helm-charts
    - https://helm.vector.dev
    - https://github.com/f5xc-TenantOps/f5xc-tops-mgmt-cluster.git
  destinations:
    - namespace: observability
      server: https://kubernetes.default.svc
  clusterResourceWhitelist:
    - group: ""
      kind: Namespace
```

---

## Implementation Order

### Phase 0: Documentation & Bootstrap Updates
1. [ ] Update `bootstrap.md` to be cluster-agnostic (remove microk8s-specific instructions)
2. [ ] Document cluster prerequisites (ArgoCD required, ingress/cert-manager recommended)
3. [ ] Add namespace pre-creation to bootstrap process (terrakube, observability, tfc-operator-system)
4. [ ] Document per-project bootstrap secrets pattern

### Phase 1: Foundation
5. [ ] Create `observability/` directory structure
6. [ ] Create `terraform/` directory structure
7. [ ] Update `.gitignore` with new entries
8. [ ] Create ArgoCD Project for observability

### Phase 2: AWS Infrastructure
9. [ ] Write `terraform/aws-monitoring-infra/` Terraform
10. [ ] Bootstrap Terrakube workspace for AWS infra (manual first run)
11. [ ] Apply Terraform to create S3 bucket and IAM user
12. [ ] Configure F5 XC Global Log Receivers (manual in F5 XC console)

### Phase 3: Observability Components
13. [ ] Create Prometheus ArgoCD App + values
14. [ ] Create Loki ArgoCD App + values
15. [ ] Create Vector ArgoCD App + values (configured for S3 source)
16. [ ] Create Grafana ArgoCD App + values
17. [ ] Create f5xc-prom-exporter manifests + ArgoCD App
18. [ ] Create `observability-bootstrap.yml` from example and apply

### Phase 4: Terrakube Self-Management
19. [ ] Write `terraform/terrakube-workspaces/` Terraform
20. [ ] Create SSH deploy key for this repo
21. [ ] Update `terrakube-bootstrap.yml` with SSH key and apply
22. [ ] Bootstrap `terrakube-self` workspace (manual first run)
23. [ ] Verify self-management loop works

### Phase 5: Dashboards & Alerting
24. [ ] Create Grafana dashboards for F5 XC metrics
25. [ ] Create Grafana dashboards for cluster metrics
26. [ ] Create Grafana dashboards for Lambda metrics
27. [ ] Configure alerting rules in Prometheus

---

## Out of Scope

- Migration of `tfc-operator` workspaces (future project)
- Ingress/external access to observability UIs (if needed, separate task)
- High availability configuration for observability components

---

## Open Questions

1. **Lambda metrics** - Are we using YACE (Yet Another CloudWatch Exporter) or another method to get Lambda metrics into Prometheus?

2. **F5 XC Tenant Names** - What are the 3 tenant names for the exporter configuration?

3. **Grafana authentication** - Same LDAP/Dex setup as Terrakube, or simpler auth?

4. **Alerting destinations** - Where should alerts go? (Slack, email, PagerDuty, etc.)
