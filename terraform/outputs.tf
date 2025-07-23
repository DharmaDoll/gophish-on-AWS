
output "ec2_public_ip" {
  description = "Public IP address of the Gophish EC2 instance."
  value       = aws_ec2_instance.main.public_ip
}

output "gophish_admin_url" {
  description = "The URL for the Gophish admin interface."
  value       = "https://gophish.${var.domain_name}:3333"
}

output "gophish_phish_url" {
  description = "The URL for the Gophish phishing site."
  value       = "http://phish.${var.domain_name}"
}

output "ses_smtp_endpoint" {
  description = "The Amazon SES SMTP endpoint for sending emails."
  value       = "email-smtp.${var.aws_region}.amazonaws.com"
}

output "ses_smtp_ports" {
  description = "Common Amazon SES SMTP ports."
  value       = "25, 465 (SSL/TLS), 587 (STARTTLS)"
}

output "route53_name_servers" {
  description = "Name servers for the Route 53 hosted zone. Update your domain registrar with these."
  value       = aws_route53_zone.main.name_servers
}
