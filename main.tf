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

resource "aws_security_group" "test-app-security-group" {
  name   = "test-app-sg"
  vpc_id = aws_vpc.test-app-vpc.id

  // inbound traffic
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // outbound traffic port: 0 => any port, protocol: -1 => all
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-sg"
  }
}

data "aws_ami" "aws-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

}


resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key-tf-generated"
  public_key = file(var.public_key_location)

}

resource "aws_instance" "test-app-ec2" {
  ami           = data.aws_ami.aws-linux-image.id
  instance_type = var.instance_type

  // optional
  subnet_id                   = module.test-app-subnet.subnet.id
  vpc_security_group_ids      = [aws_security_group.test-app-security-group.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  // executed 1 time
  user_data_replace_on_change = true
  user_data                   = file("entry-script.sh")

  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-ec2"
  }
}
