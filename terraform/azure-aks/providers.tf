terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
    kustomization = {
      source  = "kbst/kustomization"
    }
    github = {
      source = "integrations/github"
    }
  }
}

provider "azurerm" {
  features { }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  username               = azurerm_kubernetes_cluster.aks.kube_config.0.username
  password               = azurerm_kubernetes_cluster.aks.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

provider "kustomization" {
  kubeconfig_raw = azurerm_kubernetes_cluster.aks.kube_config_raw
}
