# defining the region -----

variable "region" {
  default = "eu-north-1"
}

# defining the cidr for vpc ----

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

# defining username to rds
variable "db_username" {
  default = "admin"
}

# defining password to rds
variable "db_password" {
  default = "StrongPassword123!"
  sensitive = true
}