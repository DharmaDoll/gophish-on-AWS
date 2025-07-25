
variable "aws_region" {
  description = "The AWS region to create resources in."
  type        = string
  default     = "ap-northeast-1"
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

variable "domain_name_to_register" {
  description = "The domain name to register with Route 53."
  type        = string
}

# Admin Contact Information
variable "admin_contact_first_name" { type = string }
variable "admin_contact_last_name" { type = string }
variable "admin_contact_address_line_1" { type = string }
variable "admin_contact_city" { type = string }
variable "admin_contact_state" { type = string }
variable "admin_contact_zip_code" { type = string }
variable "admin_contact_country_code" { type = string }
variable "admin_contact_email" { type = string }
variable "admin_contact_phone_number" { type = string }

# Registrant Contact Information
variable "registrant_contact_first_name" { type = string }
variable "registrant_contact_last_name" { type = string }
variable "registrant_contact_address_line_1" { type = string }
variable "registrant_contact_city" { type = string }
variable "registrant_contact_state" { type = string }
variable "registrant_contact_zip_code" { type = string }
variable "registrant_contact_country_code" { type = string }
variable "registrant_contact_email" { type = string }
variable "registrant_contact_phone_number" { type = string }

# Tech Contact Information
variable "tech_contact_first_name" { type = string }
variable "tech_contact_last_name" { type = string }
variable "tech_contact_address_line_1" { type = string }
variable "tech_contact_city" { type = string }
variable "tech_contact_state" { type = string }
variable "tech_contact_zip_code" { type = string }
variable "tech_contact_country_code" { type = string }
variable "tech_contact_email" { type = string }
variable "tech_contact_phone_number" { type = string }
