#!/usr/bin/env bash

# Small script to clean up Terraform Kubernetes resources before destorying environment

terraform state rm 'kustomization_resource.gotk'
terraform state rm 'kubernetes_secret.github'
terraform state rm 'kubernetes_namespace.gitops'

terraform plan -out plan.out -destroy
