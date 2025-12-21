# Bootstrap

This guide covers bootstrapping a Kubernetes cluster to run the F5 XC TenantOps management stack.

## Overview

The management cluster runs:
- **ArgoCD** - GitOps continuous delivery
- **Terrakube** - Self-hosted Terraform automation
- **TFC Operator** - HCP Terraform / Terraform Cloud workspaces
- **Observability Stack** - Prometheus, Grafana, Loki, Vector

## Cluster Prerequisites

### Required
- Kubernetes cluster (any distribution: microk8s, k3s, EKS, GKE, AKS, etc.)
- `kubectl` configured with cluster admin access
- ArgoCD installed and accessible

### Recommended
- **Ingress Controller** (nginx-ingress, traefik, etc.) - for external access to UIs
- **cert-manager** with a configured ClusterIssuer - for TLS certificates

---

## Step 1: Create Namespaces

Apply the namespace definitions:

```shell
kubectl apply -f bootstrap-ns.yml
```

This creates: `argocd`, `terrakube`, `observability`, `tfc-operator-system`

---

## Step 2: Prepare Bootstrap Secrets

Bootstrap secrets are organized by component. Each has a `.example` template.

### Secret Files Overview

| File | Namespace | Contents |
|------|-----------|----------|
| `tfc-bootstrap.yml` | `tfc-operator-system` | HCP Terraform token, F5 XC API creds, AWS/GCP creds |
| `terrakube-bootstrap.yml` | `terrakube` | Terrakube API token, SSH deploy key |
| `observability-bootstrap.yml` | `observability` | AWS creds (for Terraform), F5 XC tenant creds, Grafana admin |

> **Note on AWS secrets:** There are TWO AWS secrets in the observability namespace:
> - `aws-credentials` - Bootstrap secret for Terraform to CREATE S3/IAM resources
> - `vector-aws-credentials` - Created BY Terraform for Vector to READ from S3

### Create Secret Files

```shell
cp tfc-bootstrap.yml.example tfc-bootstrap.yml
cp terrakube-bootstrap.yml.example terrakube-bootstrap.yml
cp observability-bootstrap.yml.example observability-bootstrap.yml
```

### Fill in Values

#### `tfc-bootstrap.yml`

| Secret | Key | Description |
|--------|-----|-------------|
| `terraformrc` | `token` | HCP Terraform / Terraform Cloud API token |
| `tenant-tokens` | `mcn_svc_cred` | MCN Lab F5 XC API credential (base64 p12) |
| `tenant-tokens` | `mcn_svc_cred_name` | MCN Lab credential name |
| `tenant-tokens` | `sec_svc_cred` | Security Lab F5 XC API credential (base64 p12) |
| `tenant-tokens` | `sec_svc_cred_name` | Security Lab credential name |
| `tenant-tokens` | `app_svc_cred` | App Lab F5 XC API credential (base64 p12) |
| `tenant-tokens` | `app_svc_cred_name` | App Lab credential name |
| `workspacesecrets` | `AWS_ACCESS_KEY_ID` | AWS credentials for TFC workspaces |
| `workspacesecrets` | `AWS_SECRET_ACCESS_KEY` | AWS credentials for TFC workspaces |
| `workspacesecrets` | `ZONE_ID` | Cloudflare zone ID |
| `workspacesecrets` | `ACME_EMAIL` | Email for Let's Encrypt |
| `workspacesecrets` | `UDF_PRINCIPAL_ORG_PATH` | UDF org path |
| `workspacesecrets` | `GCP_PROJECT_ID` | GCP project ID |
| `workspacesecrets` | `GCP_CREDENTIALS` | GCP service account JSON |

#### `terrakube-bootstrap.yml`

| Secret | Key | Description |
|--------|-----|-------------|
| `terrakube-api-secrets` | `TERRAKUBE_TOKEN` | Terrakube API token (for self-management) |
| `terrakube-api-secrets` | `SSH_PRIVATE_KEY` | SSH deploy key for VCS polling |

To generate the SSH deploy key (Terrakube requires RSA in PEM format):
```shell
ssh-keygen -t rsa -b 4096 -m PEM -C "terrakube-deploy-key" -f terrakube-deploy-key -N ""
# Verify the key starts with "-----BEGIN RSA PRIVATE KEY-----" (not "BEGIN OPENSSH")
# Add terrakube-deploy-key.pub as a deploy key in GitHub
# Copy contents of terrakube-deploy-key into SSH_PRIVATE_KEY
```

#### `observability-bootstrap.yml`

| Secret | Key | Description |
|--------|-----|-------------|
| `aws-credentials` | `AWS_ACCESS_KEY_ID` | AWS key with S3/IAM create permissions |
| `aws-credentials` | `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `aws-credentials` | `AWS_REGION` | AWS region (e.g., us-east-1) |
| `f5xc-tenant-credentials` | `TENANT1_NAME` | First tenant name (e.g., "mcn-lab") |
| `f5xc-tenant-credentials` | `TENANT1_TENANT_URL` | First tenant URL (e.g., https://tenant.console.ves.volterra.io) |
| `f5xc-tenant-credentials` | `TENANT1_TOKEN` | First tenant API token |
| `f5xc-tenant-credentials` | `TENANT2_*` | Second tenant credentials |
| `f5xc-tenant-credentials` | `TENANT3_*` | Third tenant credentials |
| `grafana-admin` | `admin-user` | Grafana admin username |
| `grafana-admin` | `admin-password` | Grafana admin password |

The `aws-credentials` secret needs permissions to create S3 buckets and IAM users/policies. Terraform will use these credentials to create infrastructure, then create a separate `vector-aws-credentials` secret with read-only access for Vector.

### Apply Secrets

```shell
kubectl apply -f tfc-bootstrap.yml
kubectl apply -f terrakube-bootstrap.yml
kubectl apply -f observability-bootstrap.yml
```

> **Important:** These files are gitignored. Never commit real secrets.

---

## Step 3: Configure ArgoCD

Create ArgoCD configuration files for your environment (these are gitignored):

```shell
# Create argocd-config.yml with your OIDC/Dex configuration
# Create argocd-ingress.yml with your ingress settings

kubectl replace -f argocd-config.yml
kubectl apply -f argocd-ingress.yml
```

Update the admin password if needed:
```shell
argocd account update-password \
  --account admin \
  --current-password <current-password> \
  --new-password <new-password>
```

---

## Step 4: Apply Root ArgoCD Application

The root application syncs all other applications via the App of Apps pattern:

```shell
kubectl apply -f argocd/argocd-app.yml
```

ArgoCD will sync:
- Terrakube (Helm chart)
- TFC Operator (Helm chart)
- Observability stack (Prometheus, Grafana, Loki, Vector)

---

## Step 5: Bootstrap Terrakube Self-Management

Terrakube manages its own configuration via Terraform, but the initial workspace must be created manually.

### 5.1 Create Organization

In Terrakube UI, create an organization named `terrakube`.

### 5.2 Create VCS Connection

Create an SSH VCS connection:
- **Name:** `github-ssh`
- **SSH Private Key:** Same key from `terrakube-bootstrap.yml`
- **Repository:** `git@github.com:f5xc-TenantOps/f5xc-tops-mgmt-cluster.git`

### 5.3 Create Bootstrap Workspace

Create a workspace in the `terrakube` org:
- **Name:** `terrakube-config`
- **VCS:** Point to `terraform/terrakube/`
- **No variables needed** - Terraform reads secrets from Kubernetes

### 5.4 Run the Workspace

Trigger a run. This creates:
- Organization: `infrastructure`
- VCS connection for the infrastructure org
- Workspace: `observability-aws`

---

## Step 6: Create AWS Infrastructure

The `observability-aws` workspace (created in Step 5) provisions AWS resources for log collection.

### What It Creates

1. **S3 Bucket** (`f5xc-tops-global-logs`) - Receives logs from F5 XC Global Log Receivers
2. **IAM User** (`vector-log-reader`) - Read-only access to the S3 bucket
3. **Kubernetes Secret** (`vector-aws-credentials`) - IAM credentials for Vector

### Run the Workspace

In Terrakube, navigate to the `infrastructure` org and trigger a run on `observability-aws`.

The Terraform reads `aws-credentials` from Kubernetes (applied in Step 2), creates the AWS resources, and writes `vector-aws-credentials` back to the cluster for Vector to use.

### Configure F5 XC Global Log Receivers

After the workspace completes, configure F5 XC Global Log Receivers in the F5 XC console to write logs to the S3 bucket.

---

## Step 7: Verify Deployment

### Check ArgoCD Applications

```shell
kubectl get applications -n argocd
```

All should show `Synced` and `Healthy`.

### Check Observability Stack

```shell
kubectl get pods -n observability
```

### Check Terrakube

```shell
kubectl get pods -n terrakube
```

### Verify Vector AWS Secret

```shell
kubectl get secret vector-aws-credentials -n observability
```

This secret should exist after the `observability-aws` workspace runs successfully.

---

## Troubleshooting

### ArgoCD App Not Syncing

```shell
kubectl describe application <app-name> -n argocd
```

### Terrakube Workspace Failing

Check the Terrakube executor logs and ensure:
- Kubernetes secrets exist and are readable
- Service account has correct RBAC permissions

### Vector Not Pulling Logs

1. Verify the secret exists:
   ```shell
   kubectl get secret vector-aws-credentials -n observability
   ```

2. Check Vector logs:
   ```shell
   kubectl logs -l app=vector -n observability
   ```

### terraform/terrakube Workspace Fails

The workspace reads two secrets from Kubernetes:
- `terrakube-api-secrets` in `terrakube` namespace
- `aws-credentials` in `observability` namespace

Verify both exist:
```shell
kubectl get secret terrakube-api-secrets -n terrakube
kubectl get secret aws-credentials -n observability
```

---

## Architecture Reference

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              BOOTSTRAP FLOW                             │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  1. kubectl apply -f bootstrap-ns.yml                                   │
│  2. kubectl apply -f *-bootstrap.yml (secrets)                          │
│  3. kubectl apply -f argocd/argocd-app.yml                              │
│                        │                                                │
│                        ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  ArgoCD syncs all applications                                  │   │
│  │  • Terrakube (Helm)                                             │   │
│  │  • TFC Operator (Helm)                                          │   │
│  │  • Observability components (Helm + manifests)                  │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                        │                                                │
│                        ▼                                                │
│  4. Manual: Create terrakube org + terrakube-config workspace           │
│                        │                                                │
│                        ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Terrakube runs terraform/terrakube/                            │   │
│  │  • Reads: terrakube-api-secrets, aws-credentials                │   │
│  │  • Creates: infrastructure org, observability-aws workspace     │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                        │                                                │
│                        ▼                                                │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  Terrakube runs terraform/aws-monitoring-infra/                 │   │
│  │  • Creates: S3 bucket, IAM user                                 │   │
│  │  • Creates: vector-aws-credentials secret                       │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                        │                                                │
│                        ▼                                                │
│  5. Manual: Configure F5 XC Global Log Receivers → S3                   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Secrets Reference

| Secret | Namespace | Created By | Used By |
|--------|-----------|------------|---------|
| `terraformrc` | tfc-operator-system | Bootstrap | TFC Operator |
| `tenant-tokens` | tfc-operator-system | Bootstrap | TFC Operator |
| `workspacesecrets` | tfc-operator-system | Bootstrap | TFC Operator |
| `terrakube-api-secrets` | terrakube | Bootstrap | Terrakube, terraform/terrakube |
| `aws-credentials` | observability | Bootstrap | terraform/terrakube |
| `f5xc-tenant-credentials` | observability | Bootstrap | f5xc-prom-exporter |
| `grafana-admin` | observability | Bootstrap | Grafana |
| `vector-aws-credentials` | observability | Terraform | Vector |
