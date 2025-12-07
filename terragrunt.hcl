# =====================================================================
# Root Terragrunt Config (DRY backend + provider config)
# =====================================================================

remote_state {
  backend = "s3"
  config = {
    bucket         = "muticloud-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"

  contents = <<EOF
provider "aws" {
  region = "us-east-1"
}
EOF
}
