output "alb_dns_name" {
  value		= aws_lb.tf_web_service.dns_name
  description	= "The FQDN of the load balancer"
}

output "alb_security_group_id" {
  value		= aws_security_group.sg_alb.id
  description	= "The ID of the Security Group attached to the ALB"
}

output "asg_name" {
  value		= aws_autoscaling_group.example_web_cluster.name
  description	= "The name of the Autoscaling Group"
}
