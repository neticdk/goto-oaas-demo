terraform {
  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
    }
    github = {
      source = "integrations/github"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "kubernetes" {
  host                   = aws_eks_cluster.utility.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.utility.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.utility.token
}

provider "kustomization" {
  kubeconfig_raw = local.kubeconfig
}
