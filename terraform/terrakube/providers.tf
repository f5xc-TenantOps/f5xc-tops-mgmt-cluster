terraform {
  required_version = ">= 1.0"

  required_providers {
    terrakube = {
      source  = "AzBuilder/terrakube"
      version = "~> 0.15"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "terrakube" {
  endpoint = var.terrakube_endpoint
  token    = data.kubernetes_secret.terrakube_api.data["TERRAKUBE_TOKEN"]
}

provider "kubernetes" {
  # When running in Terrakube, uses in-cluster config automatically
  # For local development, set KUBECONFIG or use config_path
}
