output "alb_dns_name" {
  value = aws_lb.opa_alb.dns_name
}

output "alb_url" {
  value = "http://${aws_lb.opa_alb.dns_name}"
}
