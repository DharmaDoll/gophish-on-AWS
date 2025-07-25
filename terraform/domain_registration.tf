# Route 53 Domain Registration
resource "aws_route53domains_registered_domain" "main" {
  domain_name = var.domain_name_to_register

  admin_contact {
    first_name   = var.admin_contact_first_name
    last_name    = var.admin_contact_last_name
    address_line_1 = var.admin_contact_address_line_1
    city         = var.admin_contact_city
    state        = var.admin_contact_state
    zip_code     = var.admin_contact_zip_code
    country_code = var.admin_contact_country_code
    email        = var.admin_contact_email
    phone_number = var.admin_contact_phone_number
  }

  registrant_contact {
    first_name   = var.registrant_contact_first_name
    last_name    = var.registrant_contact_last_name
    address_line_1 = var.registrant_contact_address_line_1
    city         = var.registrant_contact_city
    state        = var.registrant_contact_state
    zip_code     = var.registrant_contact_zip_code
    country_code = var.registrant_contact_country_code
    email        = var.registrant_contact_email
    phone_number = var.registrant_contact_phone_number
  }

  tech_contact {
    first_name   = var.tech_contact_first_name
    last_name    = var.tech_contact_last_name
    address_line_1 = var.tech_contact_address_line_1
    city         = var.tech_contact_city
    state        = var.tech_contact_state
    zip_code     = var.tech_contact_zip_code
    country_code = var.tech_contact_country_code
    email        = var.tech_contact_email
    phone_number = var.tech_contact_phone_number
  }

  auto_renew = true
  # transfer_lock = true # Uncomment if you want to enable transfer lock
}
