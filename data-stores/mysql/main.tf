provider "aws" {
  region	= "us-east-1"
}

resource "aws_db_instance" "webapp_db" {
  identifier_prefix	= "${var.db_identifier_prefix}-"
  engine		= "mysql"
  allocated_storage	= 10
  instance_class	= var.db_instance_class
  skip_final_snapshot	= true
  db_name		= var.db_name

  # How should we set the username and password?
  username = var.db_username
  password = var.db_password
}
