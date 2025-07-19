
# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "gophish-ec2-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Secrets Manager and CloudWatch
resource "aws_iam_policy" "gophish_policy" {
  name        = "gophish-policy"
  description = "Policy for Gophish EC2 instance"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["secretsmanager:GetSecretValue"],
        Effect   = "Allow",
        Resource = aws_secretsmanager_secret.smtp.arn
      },
      {
        Action   = ["cloudwatch:PutLogEvents", "cloudwatch:CreateLogStream", "cloudwatch:CreateLogGroup"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Action   = ["s3:PutObject"],
        Effect   = "Allow",
        Resource = "${aws_s3_bucket.session_logs.arn}/*"
      },
      {
        Action   = ["cloudwatch:CreateLogStream", "cloudwatch:PutLogEvents", "cloudwatch:DescribeLogGroups", "cloudwatch:DescribeLogStreams"],
        Effect   = "Allow",
        Resource = "${aws_cloudwatch_log_group.session_logs.arn}:*"
      }
    ]
  })
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.gophish_policy.arn
}

# Attach SSM Managed Policy to Role
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "gophish-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance
resource "aws_ec2_instance" "main" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.main.id
  vpc_security_group_ids = [
    aws_security_group.gophish_admin.id,
    aws_security_group.gophish_phish.id
  ]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker amazon-efs-utils certbot
              systemctl enable docker
              systemctl start docker
              usermod -a -G docker ec2-user
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose

              # Create config.json
              cat <<EOF > /efs/config.json
${file("config.json.tpl")}
EOF

              # Create docker-compose.yml
              cat <<EOF > /efs/docker-compose.yml
version: '3.7'
services:
  gophish:
    image: gophish/gophish:latest
    container_name: gophish
    restart: always
    ports:
      - "3333:3333"   # Admin UI
      - "80:8080"     # Phishing Site (HTTP)
      - "443:8443"    # Phishing Site (HTTPS)
    volumes:
      - /efs:/opt/gophish
EOF

              # Start Gophish
              sudo docker-compose -f /efs/docker-compose.yml up -d
              EOF

              # Create config.json
              cat <<EOF > /efs/config.json
${file("config.json.tpl")}
EOF

              # Create docker-compose.yml
              cat <<EOF > /efs/docker-compose.yml
version: '3.7'
services:
  gophish:
    image: gophish/gophish:latest
    container_name: gophish
    restart: always
    ports:
      - "3333:3333"   # Admin UI
      - "80:8080"     # Phishing Site (HTTP)
      - "443:8443"    # Phishing Site (HTTPS)
    volumes:
      - /efs:/opt/gophish
EOF

              # Start Gophish
              sudo docker-compose -f /efs/docker-compose.yml up -d
              EOF

  tags = {
    Name = "gophish-instance"
  }
}

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# CloudWatch Log Group for Session Manager logs
resource "aws_cloudwatch_log_group" "session_logs" {
  name              = "/ssm/session-logs"
  retention_in_days = 90
}
