output "role_arn_ci" {
  description = "ARN of the CI role — set as AWS_ROLE_ARN in GitHub Actions secrets."
  value       = aws_iam_role.ci.arn
}

output "role_arn_staging" {
  description = "ARN of the staging CD role — set as AWS_ROLE_ARN_STAGING in GitHub Actions secrets."
  value       = aws_iam_role.staging.arn
}

output "role_arn_production" {
  description = "ARN of the production CD role — set as AWS_ROLE_ARN_PRODUCTION in GitHub Actions secrets."
  value       = aws_iam_role.production.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider created in this AWS account."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_secrets_summary" {
  description = "Copy-paste values for GitHub Actions secrets."
  value = {
    AWS_ROLE_ARN            = aws_iam_role.ci.arn
    AWS_ROLE_ARN_STAGING    = aws_iam_role.staging.arn
    AWS_ROLE_ARN_PRODUCTION = aws_iam_role.production.arn
  }
}
