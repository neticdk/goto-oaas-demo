locals {
  creator = "Netic"
  service = "OaaS Global"
  owner   = "Netic PD"
  cluster = "aws-eks-utility"
  common_tags = {
    Creator = local.creator
    Service = local.service
    Owner   = local.owner
    Cluster = local.cluster
  }
  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.utility.endpoint}
    certificate-authority-data: ${aws_eks_cluster.utility.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    token: ${data.aws_eks_cluster_auth.utility.token}
KUBECONFIG
}

data "aws_availability_zones" "available" {}

resource "tls_private_key" "github_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "github_repository_deploy_key" "gotk" {
  title      = "GitOps Toolkit deployment key"
  repository = var.github_repo
  key        = tls_private_key.github_key.public_key_openssh
  read_only  = "true"
}

resource "aws_iam_role" "eks_cluster" {
  name = "aws-eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_eks_cluster" "utility" {
  name     = "aws-eks-utility"
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.node_subnet.*.id
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSVPCResourceController,
  ]
}

data "aws_eks_cluster_auth" "utility" {
  name = "aws-eks-utility"
}

resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.utility.name
  node_group_name = "eks_nodes"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = aws_subnet.node_subnet.*.id

  scaling_config {
    desired_size = 3
    max_size     = 3
    min_size     = 3
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "local_file" "kubeconfig" {
  filename          = "kube_config.yaml"
  sensitive_content = local.kubeconfig
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
  path = "${path.module}/../../gotk/clusters/aws-eks/bootstrap"
}

resource "kustomization_resource" "gotk" {
  for_each = data.kustomization_build.gotk.ids
  manifest = data.kustomization_build.gotk.manifests[each.value]
  depends_on = [
    kubernetes_secret.github
  ]
}
