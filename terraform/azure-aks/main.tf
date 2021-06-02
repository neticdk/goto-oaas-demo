resource "tls_private_key" "github_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "github_repository_deploy_key" "gotk" {
  title      = "GitOps Toolkit deployment key - azure-aks"
  repository = var.github_repo
  key        = tls_private_key.github_key.public_key_openssh
  read_only  = "true"
}

resource "azurerm_resource_group" "aks" {
  name     = "goto-azure-aks"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "azure-aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "azure-aks"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_B2ms"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Creator = "Netic"
    Service = "OaaS Global"
    Owner   = "Netic PD"
    Cluster = "azure-aks-utility"
  }
}

resource "local_file" "kubeconfig" {
  filename          = "kube_config.yaml"
  sensitive_content = azurerm_kubernetes_cluster.aks.kube_config_raw
  file_permission   = "0600"
}

resource "kubernetes_namespace" "gitops" {
  metadata {
    labels = {
      name = "netic-gitops-system"
    }

    name = "netic-gitops-system"
  }
}

resource "kubernetes_secret" "github" {
  metadata {
    name = "flux-system"
    namespace = "netic-gitops-system"
  }

  data = {
    identity = tls_private_key.github_key.private_key_pem
    "identity.pub" = tls_private_key.github_key.public_key_openssh
    "known_hosts" = <<KNOWNHOSTS
github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==
KNOWNHOSTS
  }

  depends_on = [
    kubernetes_namespace.gitops
  ]
}

data "kustomization_build" "gotk" {
  path = "${path.module}/../../gotk/clusters/azure-aks/bootstrap"
}

resource "kustomization_resource" "gotk" {
  for_each = data.kustomization_build.gotk.ids
  manifest = data.kustomization_build.gotk.manifests[each.value]
  depends_on = [
    kubernetes_secret.github
  ]
}
