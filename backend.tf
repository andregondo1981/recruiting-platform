terraform {
  backend "s3" {
    bucket          = "resume-portal-server-bucket" # Replace with a globally unique bucket name
    key             = "prod/terraform.tfstate"
    region          = "us-east-1"
    use_lockfile = true
    encrypt         = true
  }
}
