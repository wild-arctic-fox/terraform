output "ec2_public_ip" {
  value = aws_instance.test-app-ec2.public_ip
}
