
# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token = "gophish-efs"

  tags = {
    Name = "gophish-efs"
  }
}

# EFS Mount Target
resource "aws_efs_mount_target" "main" {
  file_system_id = aws_efs_file_system.main.id
  subnet_id      = aws_subnet.main.id
  security_groups = [aws_security_group.gophish_phish.id] # Allow access from EC2
}

# S3 Bucket for Session Manager logs
resource "aws_s3_bucket" "session_logs" {
  bucket = "gophish-session-logs-${data.aws_caller_identity.current.account_id}"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 90
    }
  }
}

data "aws_caller_identity" "current" {}
