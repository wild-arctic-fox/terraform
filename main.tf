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

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}
variable "private_key_location" {}

resource "aws_vpc" "test-app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-vpc"
  }
}


resource "aws_subnet" "test-app-subnet-1" {
  cidr_block        = var.subnet_cidr_block
  vpc_id            = aws_vpc.test-app-vpc.id
  availability_zone = var.avail_zone
  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-subnet-1"
  }
}

// VPC component that allows communication between your VPC and the internet. It supports IPv4 and IPv6 traffic.
// An internet gateway provides a target in your VPC route tables for internet-routable traffic.
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
# virtual modem that connects to Internet
resource "aws_internet_gateway" "test-app-gateway" {
  vpc_id = aws_vpc.test-app-vpc.id
  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-app-gateway"
  }
}

// A route table contains a set of rules, called routes, 
// that determine where network traffic from your subnet or gateway is directed.
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html
# virtual router inside VPC
resource "aws_route_table" "test-app-route-table" {
  vpc_id = aws_vpc.test-app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.test-app-gateway.id
  }
  tags = {
    terraform = "true"
    Name      = "${var.env_prefix}-route-table"
  }
}

resource "aws_route_table_association" "test-app-route-table-association" {
  subnet_id      = aws_subnet.test-app-subnet-1.id
  route_table_id = aws_route_table.test-app-route-table.id
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
  subnet_id                   = aws_subnet.test-app-subnet-1.id
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

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  // Provisioners are NOT RECOMMENDED
  // The file provisioner copies file from local to remote 
  provisioner "file" {
    source      = "entry-script.sh"
    destination = "/home/ec2-user/entry-script.sh"
  }

  // The remote-exec provisioner invokes a script on a remote resource after it is created. 
  provisioner "remote-exec" {
    inline = [
      "export ENV=dev",
      "touch test.txt"
    ]

    // Should exist on remote server
    // script = file("entry-script.sh")
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > output.txt"
  }
}




output "aws_ami" {
  value = data.aws_ami.aws-linux-image
}

output "ec2_public_ip" {
  value = aws_instance.test-app-ec2
}
