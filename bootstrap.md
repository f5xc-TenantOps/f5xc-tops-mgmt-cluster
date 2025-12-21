# Bootstrap

This guide covers bootstrapping a Kubernetes cluster to run the F5 XC TenantOps management stack.

## Cluster Prerequisites

### Required
- Kubernetes cluster (any distribution: microk8s, k3s, EKS, GKE, AKS, etc.)
- `kubectl` configured to access the cluster
- ArgoCD installed and accessible

### Recommended Components
- **Ingress Controller** (e.g., nginx-ingress, traefik)
  - Required for external access to UIs (ArgoCD, Terrakube, Grafana)
- **cert-manager**
  - Required for automatic TLS certificate management
  - Configure a ClusterIssuer for your domain

## Step 1: Create Namespaces

All namespaces are defined in `bootstrap-ns.yml`. Apply first:

```shell
kubectl apply -f bootstrap-ns.yml
```

This creates:
- `argocd`
- `terrakube`
- `observability`
- `tfc-operator-system`

## Step 2: Apply Bootstrap Secrets

Bootstrap secrets are organized by project. Each has a `.example` template in the repo.

| File | Namespace | Purpose |
|------|-----------|---------|
| `tfc-bootstrap.yml` | `tfc-operator-system` | HCP Terraform operator credentials |
| `terrakube-bootstrap.yml` | `terrakube` | Terrakube API and SSH keys |
| `observability-bootstrap.yml` | `observability` | AWS, F5 XC, and Grafana credentials |

Copy templates and fill in values:

```shell
cp tfc-bootstrap.yml.example tfc-bootstrap.yml
cp terrakube-bootstrap.yml.example terrakube-bootstrap.yml
cp observability-bootstrap.yml.example observability-bootstrap.yml
# Edit each file with real values
```

Apply the secrets:

```shell
kubectl apply -f tfc-bootstrap.yml
kubectl apply -f terrakube-bootstrap.yml
kubectl apply -f observability-bootstrap.yml
```

> **Note:** These files are gitignored. Never commit real secrets.

## Step 3: Configure ArgoCD

Apply ArgoCD configuration and ingress (these files are gitignored, create from your environment):

```shell
kubectl replace -f argocd-config.yml
kubectl apply -f argocd-ingress.yml
```

Optionally update the admin password:

```shell
argocd account update-password \
  --account <account-name> \
  --current-password <admin-password> \
  --new-password <new-password>
```

## Step 4: Apply Root ArgoCD Application

The root application syncs all other applications:

```shell
kubectl apply -f argocd/argocd-app.yml
```

ArgoCD will now sync:
- Terrakube
- TFC Operator
- Observability stack (Prometheus, Grafana, Loki, Vector)

## Verification

Check that all applications are synced:

```shell
kubectl get applications -n argocd
```

All applications should show `Synced` and `Healthy` status.
