terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "f5xc-tops-observability"
      ManagedBy   = "terraform"
      Environment = "production"
    }
  }
}

# Kubernetes provider uses in-cluster config when running in Terrakube
provider "kubernetes" {}
