
output "public_ip" {
  value = aws_instance.api.public_ip
}

output "public_dns" {
  value = aws_instance.api.public_dns
}

output "ssh_command" {
  value = "ssh -i TU_KEY.pem ubuntu@${aws_instance.api.public_dns}"
}