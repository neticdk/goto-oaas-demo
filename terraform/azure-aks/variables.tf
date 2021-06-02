variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure region for the cluster"
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
