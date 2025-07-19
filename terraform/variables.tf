
variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "ap-northeast-1"
}

variable "domain_name" {
  description = "The domain name for Gophish."
  type        = string
  default     = "ponponboo.com"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "my_ip" {
  description = "Your local IP address for SSH and Admin access."
  type        = string
  sensitive   = true
}
