output "vpc_id" {
  description = "ID of the VPC created for this environment."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets (used by EKS worker nodes and RDS)."
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (used by ALB / NAT Gateway)."
  value       = module.vpc.public_subnet_ids
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "API server endpoint for the EKS cluster."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC provider used for IRSA (IAM Roles for Service Accounts)."
  value       = module.eks.oidc_provider_arn
}

output "ecr_repository_url" {
  description = "Full ECR repository URL (used as Docker registry in CI/CD)."
  value       = module.ecr.repository_url
}

output "rds_endpoint" {
  description = "RDS instance endpoint (empty if enable_rds = false)."
  value       = var.enable_rds ? module.rds[0].endpoint : ""
  sensitive   = true
}
