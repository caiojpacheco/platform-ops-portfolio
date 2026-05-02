variable "aws_region" {
  description = "AWS region where the OIDC provider and IAM resources are created."
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub username or organization that owns the repository."
  type        = string
  default     = "caiojpacheco"
}

variable "github_repo" {
  description = "GitHub repository name (without the org prefix)."
  type        = string
  default     = "platform-ops-portfolio"
}
