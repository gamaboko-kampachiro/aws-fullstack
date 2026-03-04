# this will display the output of vpc

output "vpc_id" {
  value = aws_vpc.smart_vpc.id
}

output "rds_endpoint" {
  value = aws_db_instance.smart_db.endpoint
}

output "alb_dns_name" {
  description = "Public DNS of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}