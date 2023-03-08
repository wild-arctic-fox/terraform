output "aws_ami" {
  value = data.aws_ami.aws-linux-image
}

output "ec2_public_ip" {
  value = aws_instance.test-app-ec2
}