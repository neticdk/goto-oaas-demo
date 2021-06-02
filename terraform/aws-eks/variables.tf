variable "aws_region" {
  type        = string
  description = "AWS region to build cluster"
  default     = "eu-west-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range for whole vpc"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.0.0.0/25"
  description = "CIDR range for bastion subnet"
}

variable "node_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR range for node subnet"
}

variable "github_token" {
  type        = string
  description = "Token for communicating with GitHub api (registering deployment keys for flux/gotk)"
}

variable "github_owner" {
  type    = string
  default = "neticdk"
}

variable "github_repo" {
  type    = string
  default = "goto-oaas-demo"
}
