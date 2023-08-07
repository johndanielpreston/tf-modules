variable "db_username" {
  description	= "The MySQL admin username"
  type		= string
  sensitive	= true
}

variable "db_password" {
  description	= "The password for the MySQL admin account"
  type		= string
  sensitive	= true
}

variable "db_identifier_prefix" {
  description	= "Set the prefix for the service endpoint of the AWS RDS"
  type		= string
  default	= "tf-up-and-running"
}

variable "db_instance_class" {
  description	= "Set the flavor of the server which hosts the database (db.t2.micro < db.t3.micro < db.t4g.micro)"
  type		= string
  default	= "db.t2.micro"
}

variable "db_name" {
  description	= "Set a unique name for the database instance"
  type		= string
}
