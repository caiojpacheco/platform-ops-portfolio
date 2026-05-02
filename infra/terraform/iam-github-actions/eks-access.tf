# EKS Access Entries for GitHub Actions roles.
#
# Apply this AFTER the EKS cluster exists:
#   terraform apply -var="enable_eks_access=true"
#
# Uses the EKS Access Entries API (available since EKS 1.28) instead of
# patching the aws-auth ConfigMap, which is the recommended approach for
# clusters >= 1.28.

variable "enable_eks_access" {
  description = "Set to true after the EKS cluster is created to grant GitHub Actions roles cluster access."
  type        = bool
  default     = false
}

data "aws_eks_cluster" "staging" {
  count = var.enable_eks_access ? 1 : 0
  name  = "platform-ops-staging"
}

data "aws_eks_cluster" "production" {
  count = var.enable_eks_access ? 1 : 0
  name  = "platform-ops-production"
}

# ── Staging: grant staging role viewer + deploy access ───────────────────────
resource "aws_eks_access_entry" "staging_role" {
  count         = var.enable_eks_access ? 1 : 0
  cluster_name  = data.aws_eks_cluster.staging[0].name
  principal_arn = aws_iam_role.staging.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "staging_role" {
  count         = var.enable_eks_access ? 1 : 0
  cluster_name  = data.aws_eks_cluster.staging[0].name
  principal_arn = aws_iam_role.staging.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["portfolio"]
  }

  depends_on = [aws_eks_access_entry.staging_role]
}

# ── Production: grant production role deploy access (namespace-scoped) ────────
resource "aws_eks_access_entry" "production_role" {
  count         = var.enable_eks_access ? 1 : 0
  cluster_name  = data.aws_eks_cluster.production[0].name
  principal_arn = aws_iam_role.production.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "production_role" {
  count         = var.enable_eks_access ? 1 : 0
  cluster_name  = data.aws_eks_cluster.production[0].name
  principal_arn = aws_iam_role.production.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = ["portfolio"]
  }

  depends_on = [aws_eks_access_entry.production_role]
}
