resource "aws_subnet" "test-app-subnet-1" {
  cidr_block        = var.subnet_cidr_block
  vpc_id            = var.vpc_id
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
  vpc_id = var.vpc_id
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
  vpc_id = var.vpc_id
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

