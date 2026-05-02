#!/usr/bin/env bash
# bootstrap-iam.sh
#
# Provisions the GitHub Actions OIDC roles and (optionally) grants them
# EKS cluster access. Run this script ONCE before any CI/CD workflow executes.
#
# Prerequisites:
#   - AWS CLI configured with admin credentials
#   - Terraform >= 1.8 installed
#   - gh CLI authenticated (gh auth login)
#   - GITHUB_REPO env var set to your repo slug (default: caiojpacheco/platform-ops-portfolio)
#
# Usage:
#   chmod +x scripts/bootstrap-iam.sh
#   ./scripts/bootstrap-iam.sh                  # creates roles only
#   ./scripts/bootstrap-iam.sh --with-eks-access # also grants EKS access (run after EKS exists)

set -euo pipefail

REPO="${GITHUB_REPO:-caiojpacheco/platform-ops-portfolio}"
IAM_DIR="$(cd "$(dirname "$0")/../infra/terraform/iam-github-actions" && pwd)"
WITH_EKS_ACCESS=false

for arg in "$@"; do
  [[ "$arg" == "--with-eks-access" ]] && WITH_EKS_ACCESS=true
done

echo "==> Provisioning GitHub Actions IAM roles..."
cd "$IAM_DIR"

terraform init -upgrade

if [[ "$WITH_EKS_ACCESS" == "true" ]]; then
  terraform apply -auto-approve -var="enable_eks_access=true"
else
  terraform apply -auto-approve -var="enable_eks_access=false"
fi

echo ""
echo "==> Roles created. Reading ARNs from outputs..."

ROLE_ARN_CI=$(terraform output -raw role_arn_ci)
ROLE_ARN_STAGING=$(terraform output -raw role_arn_staging)
ROLE_ARN_PRODUCTION=$(terraform output -raw role_arn_production)

echo "  CI role        : $ROLE_ARN_CI"
echo "  Staging role   : $ROLE_ARN_STAGING"
echo "  Production role: $ROLE_ARN_PRODUCTION"

echo ""
echo "==> Setting GitHub Actions secrets on $REPO..."

gh secret set AWS_ROLE_ARN            --body "$ROLE_ARN_CI"         --repo "$REPO"
gh secret set AWS_ROLE_ARN_STAGING    --body "$ROLE_ARN_STAGING"    --repo "$REPO" --env staging
gh secret set AWS_ROLE_ARN_PRODUCTION --body "$ROLE_ARN_PRODUCTION" --repo "$REPO" --env production

echo ""
echo "✓  Done! GitHub Actions secrets populated:"
echo "   AWS_ROLE_ARN             (Actions > Secrets)"
echo "   AWS_ROLE_ARN_STAGING     (Environment: staging)"
echo "   AWS_ROLE_ARN_PRODUCTION  (Environment: production)"
echo ""
echo "   Next step: create the GitHub Environments in the repo settings"
echo "   https://github.com/$REPO/settings/environments"
