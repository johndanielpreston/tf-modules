terraform { 
  # This block tells Terraform to import the AWS provider from the Terraform registry.
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


# Define variables that are internal to the module.
locals {
  web_server_port	= 80
  any_port		= 0
  any_protocol		= "-1"
  tcp_protocol		= "tcp"
  the_internet		= ["0.0.0.0/0"]
}



# This block defines the default VPC as a data source.
data "aws_vpc" "default" {
  default = true
}


# This block reads in the list of subnets for the account's default VPC for use
# with the AWS autoscaling group definition.
data "aws_subnets" "default" {
  filter {
    name	= "vpc-id"
    values	= [data.aws_vpc.default.id]
  }
}


# This block reads in data from the data-sources/mysql database service Terraform state
data "terraform_remote_state" "webapp_db" {
  backend		= "s3"

  config = {
    bucket		= var.db_remote_state_bucket
    key			= var.db_remote_state_key
    region		= "us-east-1"
  }
}


# This block defines a template for a web server which will be part of an AWS autoscaling group.
resource "aws_launch_configuration" "example_web_server" {
    image_id		= "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS x86_64
    instance_type	= var.instance_type
    security_groups	= [aws_security_group.example_web_service.id]

    # Insert dynamic content via ./user-data.sh + variables
    user_data = templatefile("${path.module}/user-data.sh", {
      server_port 	= var.server_port
      db_address	= data.terraform_remote_state.webapp_db.outputs.db_instance_address
      db_port		= data.terraform_remote_state.webapp_db.outputs.db_instance_port
      })

    # The following is required when using a launch configuration with an autoscaling group.
    lifecycle {
      create_before_destroy = true
    }
}


# This block defines the clustered web service AWS autoscaling group.
resource "aws_autoscaling_group" "example_web_cluster" {
  launch_configuration	= aws_launch_configuration.example_web_server.name
  vpc_zone_identifier 	= data.aws_subnets.default.ids

  # Map the ASG cluster to the ALB service and apply a health check to determine
  # whether or not tf_web_service cluster nodes are functional.
  target_group_arns	= [aws_lb_target_group.example_web_service.arn]
  health_check_type	= "ELB"

  min_size = var.asg_min_size
  max_size = var.asg_max_size

  tag {
    key			= "Name"
    value		= var.cluster_name
    propagate_at_launch	= true
  }
}


# This block define an AWS Application Load Balancer for the web service.
resource "aws_lb" "tf_web_service" {
  name			= "${var.cluster_name}-alb"
  load_balancer_type	= "application"
  subnets		= data.aws_subnets.default.ids
  security_groups	= [aws_security_group.sg_alb.id]
}


# This block defines a listener for the example_web_cluster ASG on the
# tf_web_service ALB. 
#
# NOTE: This might be a fallback configuration?
#
resource "aws_lb_listener" "http" {
  load_balancer_arn	= aws_lb.tf_web_service.arn
  port			= local.web_server_port
  protocol		= "HTTP"

  # By default, return a simple 404 error page
  default_action {
    type 		= "fixed-response"

    fixed_response {
      content_type 	= "text/plain"
      message_body	= "404: page not found"
      status_code	= "404"
    }
  }
}


# This block defines a listener for the terraform-web-cluster ALB which forwards
# HTTP traffic to the example_web_cluster ASG servers.
resource "aws_lb_listener_rule" "asg" {
  listener_arn		= aws_lb_listener.http.arn
  priority		= 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type		= "forward"
    target_group_arn	= aws_lb_target_group.example_web_service.arn
  }
}


# This block defines an AWS security group which will be used by the
# tf_web_service ALB.
resource "aws_security_group" "sg_alb" {
  name		= "${var.cluster_name}-sg-alb"
}


resource "aws_security_group_rule" "sg_rule_http_ingress" {
  # Permit inbound traffic on TCP/80
  type			= "ingress"
  security_group_id	= aws_security_group.sg_alb.id
  from_port		= local.web_server_port
  to_port		= local.web_server_port
  protocol		= local.tcp_protocol
  cidr_blocks		= local.the_internet
}


resource "aws_security_group_rule" "sg_rule_all_outbound" {
  # Permit outbound traffic on all ports
  type		= "egress"
  security_group_id	= aws_security_group.sg_alb.id
  from_port	= local.any_port
  to_port	= local.any_port
  protocol	= local.any_protocol
  cidr_blocks	= local.the_internet
}


# This block defines a target group for the ALB's 'http' listener which points
# to the 'example_web_cluster' Autoscaling Group.
resource "aws_lb_target_group" "example_web_service" {
  name		= "${var.cluster_name}-alb-listener"
  port		= var.server_port
  protocol	= "HTTP"
  vpc_id	= data.aws_vpc.default.id

  health_check {
    path		= "/"
    protocol		= "HTTP"
    matcher		= "200"
    interval		= 15
    timeout		= 3
    healthy_threshold	= 2
    unhealthy_threshold	= 2
  }
}


# This block defines an AWS security group which permits inbound traffic from 0.0.0.0/0 > tcp/8080.
resource "aws_security_group" "example_web_service" {
  name = "${var.cluster_name}-asg-member-sg"
}

resource "aws_security_group_rule" "sg_rule_web_service" { 
  type			= "ingress"
  security_group_id	= aws_security_group.example_web_service.id
  from_port	= var.server_port
  to_port	= var.server_port
  protocol	= local.tcp_protocol
  cidr_blocks	= local.the_internet
}
