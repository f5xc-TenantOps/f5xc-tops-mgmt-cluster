# f5xc-tops-mgmt-cluster

Infrastructure management for the F5 XC TenantOps organization. This repo provisions and configures F5 Distributed Cloud tenants, labs, and supporting infrastructure using GitOps principles.

## How It Works

**ArgoCD** watches this repository and keeps the cluster in sync with what's defined here. When you push changes, ArgoCD picks them up and applies them.

**Terrakube** runs Terraform workspaces that create cloud resources (AWS, GCP) and configure F5 XC tenants. It pulls its configuration from this repo and manages state internally.

The TFC Operator namespace still handles some legacy workspaces—these will migrate to Terrakube over time.

## Repository Structure

```
├── bootstrap.md           # First-time cluster setup guide
├── bootstrap/             # Secrets and config templates for initial setup
├── argocd/                # ArgoCD application definitions
├── terraform/             # Terraform configurations (run by Terrakube)
├── terrakube/             # Terrakube Helm values
├── tfc-operator/          # TFC Operator Helm values (migrating to Terrakube)
└── observability/         # Monitoring stack (Prometheus, Grafana, Loki)
```

## Getting Started

New cluster? See [bootstrap.md](./bootstrap.md) for setup instructions.

### Quick Reference

Apply bootstrap secrets before deploying applications:

```bash
kubectl apply -f bootstrap/tfc-bootstrap.yml
kubectl apply -f bootstrap/terrakube-bootstrap.yml
```

## Components

### Infrastructure
Terraform workspaces that provision cloud resources and F5 XC tenant configurations.

### Observability
Monitoring and logging stack for visibility into tenant operations and infrastructure health.

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Terrakube Documentation](https://docs.terrakube.io/)
- [F5 Distributed Cloud Documentation](https://docs.cloud.f5.com/)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
