# Configure the AWS Provider
provider "aws" {
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
  region     = "ap-northeast-2" // 한국 리전
}
