variable "private_subnet_cidr_block" {}
variable "public_subnet_cidr_block" {}
variable "vpc_cidr_block" {}

provider "aws" {
  region = "eu-west-2"
}

# query aws api to get all azs for region
data "aws_availability_zones" "azs" {}

# ready module
module "test-app-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name = "test-app-vpc"
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.azs.names
  private_subnets = var.private_subnet_cidr_block
  public_subnets  = var.public_subnet_cidr_block


  enable_nat_gateway = true
  # creates shared common gateway for all the private subnets
  single_nat_gateway = true
  # to assign public/private ip, public/private dns
  enable_dns_hostnames = true

  putin_khuylo = true

  #  REQUIRED
  tags = {
    # to reference from another components
    "kubernetes.io/cluster/test-app-eks-cluster" = "shared"
    Terraform                                    = "true"
    Environment                                  = "dev"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/test-app-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                     = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/test-app-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"            = 1
  }
}
