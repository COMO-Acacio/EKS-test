locals {
  region = "eu-central-1"
  name   = "test-20240606--${random_string.suffix.result}"
  vpc_cidr = "172.0.0.0/16"
  azs      = ["eu-central-1a", "eu-central-1b"]
  public_subnets  = ["172.0.1.0/24", "172.0.2.0/24", "172.0.3.0/24"]
  private_subnets = ["172.0.101.0/24", "172.0.102.0/24", "172.0.103.0/24"]

  tags = {
    Example = local.name
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

provider "aws" {
  region = "eu-central-1"
}