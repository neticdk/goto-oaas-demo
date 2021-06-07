# GOTO Aarhus 2021 - OaaS Demo

The respository contains source code for Netic talk at GOTO Aarhus 2021. The purpose is to show two
main points: One is the deployment and workings of the observability packaged and one is to show
how GitOps Toolkit/Flux can be utilized to split responsibilities inside a Kubernetes cluster.

The repository is organized as follows on the `main` branch.

- `gotk` - manifests reconciled by GitOps Toolkit - applying observability to different clusters
- `manifests` - manifests that are manually applied to the cluster during the demonstration
- `terraform` - Terraform code to provision AKS and EKS clusters and bootstrap Flux/GitOps toolkit

Besides this the branch (devops-team)[https://github.com/neticdk/goto-oaas-demo/tree/devops-team] simulates
a development team or devops team deploying to a namespace inside of a Kubernetes cluster.
