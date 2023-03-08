data "aws_ami" "aws-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "test-app-security-group" {
  name   = "test-app-sg"
  vpc_id = var.vpc_id

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

resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key-tf-generated"
  public_key = file(var.public_key_location)

}

resource "aws_instance" "test-app-ec2" {
  ami           = data.aws_ami.aws-linux-image.id
  instance_type = var.instance_type

  // optional
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.test-app-security-group.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  // executed 1 time
  user_data_replace_on_change = true
  user_data                   = file("./entry-script.sh")

  tags = {
    test = "tag"
    terraform = "true"
    Name      = "${var.env_prefix}-ec2"
  }
}
