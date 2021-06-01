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
  load_config_file       = false
}
