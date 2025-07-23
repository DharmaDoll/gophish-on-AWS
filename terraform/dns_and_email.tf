
# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# Route 53 A Records
resource "aws_route53_record" "gophish" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "gophish.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_ec2_instance.main.public_ip]
}

resource "aws_route53_record" "phish" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "phish.${var.domain_name}"
  type    = "A"
  ttl     = 300
  records = [aws_ec2_instance.main.public_ip]
}

# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

# SES DKIM
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# Route 53 DKIM Records
resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = aws_route53_zone.main.zone_id
  name    = "${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${element(aws_ses_domain_dkim.main.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# Route 53 SPF Record
resource "aws_route53_record" "spf" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

# Route 53 DMARC Record
resource "aws_route53_record" "dmarc" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=none;"]
}
