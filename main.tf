terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "test-app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-vpc"
  }
}

module "test-app-subnet" {
  source            = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone        = var.avail_zone
  env_prefix        = var.env_prefix
  vpc_id            = aws_vpc.test-app-vpc.id
}

module "test-app-server" {
  source = "./modules/webserver"

  vpc_id               = aws_vpc.test-app-vpc.id
  avail_zone           = var.avail_zone
  env_prefix           = var.env_prefix
  my_ip                = var.my_ip
  instance_type        = var.instance_type
  public_key_location  = var.public_key_location
  private_key_location = var.private_key_location
  subnet_id            = module.test-app-subnet.subnet.id
}

