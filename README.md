# f5xc-tops-mgmt-cluster
Configuration for Cluster handling infrastructure deployment and monitoring tooling.

## 🥾 Bootstrap

This repo takes over once the cluster has a functional ArgoCD install.
What distro you use, how you install ArgoCD, how you expose services, certificates, ingress, etc. are out of scope.
Here's an [example](./bootstrap.md) prepping those components using microk8s.

### TFC Operator
Before deploying the terraform-cloud app, apply the bootstrap file to create the namespace and secrets:
```bash
kubectl apply -f tfc-bootstrap.yml
```

### Terrakube
Before deploying Terrakube, apply the bootstrap file to create the namespace and secrets:
```bash
kubectl apply -f terrakube-bootstrap.yml
```

## Components

### Infrastructure

### Observability



