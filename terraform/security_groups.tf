
# Admin Security Group
resource "aws_security_group" "gophish_admin" {
  name        = "gophish-admin-sg"
  description = "Allow admin access to Gophish"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS for Gophish Admin"
    from_port   = 3333
    to_port     = 3333
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    description = "Allow outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Phishing Site Security Group
resource "aws_security_group" "gophish_phish" {
  name        = "gophish-phish-sg"
  description = "Allow access to Gophish phishing site"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP for Phishing Site"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS for Phishing Site"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


