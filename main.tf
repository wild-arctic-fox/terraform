terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.1"
    }
  }
}


// want to use aws, with creds
provider "aws" {
  region = "eu-central-1"
}

resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    terraform = "true"
    Name      = "test-name-vpc-update"
  }
}


resource "aws_subnet" "dev-subnet" {
  cidr_block = "10.0.10.0/24"
  vpc_id     = aws_vpc.dev-vpc.id
}
