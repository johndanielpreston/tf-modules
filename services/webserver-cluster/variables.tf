variable "server_port" {
  description	= "The port that the server will use to run the HTTP service"
  type		= number
  default	= 8080
}

variable "cluster_name" {
  description	= "The name to use for the web server cluster resources"
  type		= string
}

variable "db_remote_state_bucket" {
  description	= "The name of the S3 bucket which contains the database's Terraform state"
  type		= string
}

variable "db_remote_state_key" {
  description	= "The path for the database's remote Terraform state in S3"
  type		= string
}

variable "instance_type" {
  description	= "The type of EC2 instance used to run the web server cluster members (e.g. t2.micro)"
  type		= string
}

variable "asg_min_size" {
  description 	= "The minimum number of EC2 instances in the ASG"
  type		= number
}

variable "asg_max_size" {
  description	= "The maximum number of EC2 instances in the ASG"
  type		= number
}

