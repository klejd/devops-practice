# Terraform Backend Configuration
# Using local state for now (state file stored on your machine)
# 
# To use S3 backend later, uncomment below:
# terraform {
#   backend "s3" {
#     bucket         = "devops-practice-terraform-state-dev"
#     key            = "dev/terraform.tfstate"
#     region         = "us-east-2"
#     encrypt        = true
#     dynamodb_table = "terraform-state-lock-dev"
#   }
# }
#
# NOTE: With local backend, state file (terraform.tfstate) will be created
# in this directory. DO NOT commit it to git!
