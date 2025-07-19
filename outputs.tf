
output "ec2_public_ip" {
  description = "Public IP address of the Gophish EC2 instance."
  value       = aws_ec2_instance.main.public_ip
}

output "gophish_admin_url" {
  description = "URL for the Gophish admin interface."
  value       = "https://gophish.${var.domain_name}:3333"
}

output "phish_url" {
  description = "URL for the phishing site."
  value       = "http://phish.${var.domain_name}"
}

output "route53_name_servers" {
  description = "Name servers for the Route 53 hosted zone. Update your domain registrar with these."
  value       = aws_route53_zone.main.name_servers
}
