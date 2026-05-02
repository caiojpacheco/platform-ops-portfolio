terraform {
  required_version = ">= 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "platform-ops-portfolio"
      ManagedBy = "terraform"
      Purpose   = "github-actions-oidc"
    }
  }
}

# ── GitHub OIDC provider (one per AWS account, shared by all repos) ───────────
# Fetches the current thumbprint directly from GitHub so it never goes stale.
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# ── Reusable trust-policy factory ────────────────────────────────────────────
# Each role pins the trust to a specific subject claim so a different repo or
# branch cannot assume it even if it shares the same OIDC provider.
locals {
  oidc_arn = aws_iam_openid_connect_provider.github.arn
  oidc_sub = "token.actions.githubusercontent.com:sub"
  repo     = "repo:${var.github_org}/${var.github_repo}"
}

data "aws_iam_policy_document" "trust_ci" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringLike"
      variable = local.oidc_sub
      # CI runs on every branch push and pull_request event
      values = [
        "${local.repo}:ref:refs/heads/*",
        "${local.repo}:pull_request",
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "trust_staging" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringLike"
      variable = local.oidc_sub
      # Staging CD triggers only on pull_request events
      values = ["${local.repo}:pull_request"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "trust_production" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = local.oidc_sub
      # Production CD triggers only on pushes to main
      values = ["${local.repo}:ref:refs/heads/main"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# ── ECR permissions ───────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ecr_push" {
  # GetAuthorizationToken is account-scoped, not resource-scoped
  statement {
    sid       = "ECRAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ECRPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:DescribeRepositories",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/platform-ops-*",
    ]
  }
}

resource "aws_iam_policy" "ecr_push" {
  name        = "platform-ops-ecr-push"
  description = "Allows GitHub Actions CI to push images to ECR."
  policy      = data.aws_iam_policy_document.ecr_push.json
}

# ── EKS deploy permissions ────────────────────────────────────────────────────
data "aws_iam_policy_document" "eks_deploy" {
  statement {
    sid = "EKSRead"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]
    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/platform-ops-*",
    ]
  }

  # ECR pull is needed by the deploy jobs to resolve image digests
  statement {
    sid       = "ECRAuthDeploy"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ECRPull"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/platform-ops-*",
    ]
  }
}

resource "aws_iam_policy" "eks_deploy" {
  name        = "platform-ops-eks-deploy"
  description = "Allows GitHub Actions CD jobs to describe EKS and pull ECR images."
  policy      = data.aws_iam_policy_document.eks_deploy.json
}

# ── Role: CI (lint / test / build / push / scan) ─────────────────────────────
resource "aws_iam_role" "ci" {
  name               = "platform-ops-github-actions-ci"
  assume_role_policy = data.aws_iam_policy_document.trust_ci.json
  description        = "Assumed by GitHub Actions CI workflow (any branch / PR)."
}

resource "aws_iam_role_policy_attachment" "ci_ecr" {
  role       = aws_iam_role.ci.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

# ── Role: CD Staging ──────────────────────────────────────────────────────────
resource "aws_iam_role" "staging" {
  name               = "platform-ops-github-actions-staging"
  assume_role_policy = data.aws_iam_policy_document.trust_staging.json
  description        = "Assumed by GitHub Actions CD staging workflow (pull_request events)."
}

resource "aws_iam_role_policy_attachment" "staging_eks" {
  role       = aws_iam_role.staging.name
  policy_arn = aws_iam_policy.eks_deploy.arn
}

# ── Role: CD Production ───────────────────────────────────────────────────────
resource "aws_iam_role" "production" {
  name               = "platform-ops-github-actions-production"
  assume_role_policy = data.aws_iam_policy_document.trust_production.json
  description        = "Assumed by GitHub Actions CD production workflow (push to main only)."
}

resource "aws_iam_role_policy_attachment" "production_eks" {
  role       = aws_iam_role.production.name
  policy_arn = aws_iam_policy.eks_deploy.arn
}
