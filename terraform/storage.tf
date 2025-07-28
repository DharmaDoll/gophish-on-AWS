
# EFS File System
resource "aws_efs_file_system" "main" {
  creation_token = "gophish-efs"
  encrypted      = true

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

resource "aws_s3_bucket" "log_bucket" {
  bucket = "gophish-access-logs-${data.aws_caller_identity.current.account_id}"

  lifecycle_rule {
    enabled = true
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "log_bucket_access" {
  bucket = aws_s3_bucket.log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "log_bucket_versioning" {
  bucket = aws_s3_bucket.log_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
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

resource "aws_s3_bucket_logging" "session_logs_logging" {
  bucket = aws_s3_bucket.session_logs.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_public_access_block" "session_logs_access" {
  bucket = aws_s3_bucket.session_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "session_logs_versioning" {
  bucket = aws_s3_bucket.session_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}
