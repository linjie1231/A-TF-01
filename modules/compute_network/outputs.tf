output "private_ip" {
  value       = aws_instance.web_server.private_ip
  description = "The private IP address of the EC2 instance"
}
