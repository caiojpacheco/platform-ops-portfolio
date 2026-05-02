# Remote state stored in S3 with DynamoDB locking.
# Create the bucket and table once manually (or via bootstrap script)
# before running terraform init.
terraform {
  backend "s3" {
    bucket         = "platform-ops-terraform-state"
    key            = "platform-ops/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "platform-ops-terraform-lock"
  }
}
