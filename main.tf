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
  region     = "eu-central-1"
  access_key = "AKIATRGLIIG3E4UBC3EA"
  secret_key = "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"
}

resource "aws_vpc" "dev-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    terraform = "true"
    Name      = "test-name-vpc"
  }
}


resource "aws_subnet" "dev-subnet" {
  cidr_block = "10.0.10.0/24"
  vpc_id     = aws_vpc.dev-vpc.id
}

data "" "name" {
  
}
