## ECS OPA Service Module

Terraform module that deploys an Open Policy Agent (OPA) service on AWS ECS Fargate behind an Application Load Balancer (ALB). It provisions the ECS task definition, service, ALB, target group, listener, security groups, and CloudWatch log group needed to run OPA as a dedicated policy service.

## What This Module Creates

- ECS Fargate task definition and service for OPA.
- ALB + target group + listener to expose OPA over HTTP.
- Security groups that allow ALB -> ECS traffic on the OPA port.
- CloudWatch log group for container logs (14-day retention).

## Key Behaviors and Defaults

- Fargate task uses `awsvpc` networking with `256` CPU and `512` memory.
- ALB listens on HTTP port 80; ALB is internet-facing.
- ECS tasks do not get public IPs; they are placed in private subnets.
- ECS health check uses `opa_health_check_path`; ALB target group health check path is `/health`.
- Desired count defaults to `3`.

## Usage

```hcl
module "opa_service" {
  source = "path/to/tf-ecs-opa-service-module"

  region                 = var.region
  vpc_id                 = var.vpc_id
  cluster_id             = aws_ecs_cluster.main.id
  public_subnet_ids       = var.public_subnet_ids
  private_subnet_ids      = var.private_subnet_ids
  public_network_ip_range = ["203.0.113.0/24"]

  opa_service_name      = "opa"
  opa_repository_url    = aws_ecr_repository.opa.repository_url
  opa_tag               = "latest"
  opa_container_port    = 8181
  opa_health_check_path = "/health"

  task_execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn           = aws_iam_role.ecs_task.arn

  tags = {
    Environment = "dev"
    Service     = "opa"
  }
}
```

## Notes

- The target group health check path is fixed to `/health`. Ensure your OPA server serves a 200 response at this path (or adjust the module if you need a different endpoint).
- If you need TLS termination, add an HTTPS listener and certificates outside this module (or extend it).

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.opa_log_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_service.opa_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.opa_td](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_lb.opa_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.opa_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group.opa_tg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_security_group.opa_alb_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.opa_ecs_sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.opa_alb_sg_egress_8181](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.opa_alb_sg_ingress_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.opa_sg_egress_all](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.opa_sg_ingress_8181](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ECS cluster ID where the OPA service is deployed. | `string` | n/a | yes |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | Desired number of OPA tasks. | `number` | `3` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (e.g., dev, staging, prod). | `string` | n/a | yes |
| <a name="input_opa_container_port"></a> [opa\_container\_port](#input\_opa\_container\_port) | Port exposed by the OPA container. | `number` | `8181` | no |
| <a name="input_opa_cpu"></a> [opa\_cpu](#input\_opa\_cpu) | CPU units for the OPA task. | `number` | `256` | no |
| <a name="input_opa_health_check_path"></a> [opa\_health\_check\_path](#input\_opa\_health\_check\_path) | HTTP path used for OPA health checks. | `string` | `"/health"` | no |
| <a name="input_opa_memory"></a> [opa\_memory](#input\_opa\_memory) | Memory in MiB for the OPA task. | `number` | `512` | no |
| <a name="input_opa_repository_url"></a> [opa\_repository\_url](#input\_opa\_repository\_url) | ECR repository URL for the OPA image. | `string` | n/a | yes |
| <a name="input_opa_service_name"></a> [opa\_service\_name](#input\_opa\_service\_name) | OPA service name used for ECS and ALB resources. | `string` | n/a | yes |
| <a name="input_opa_tag"></a> [opa\_tag](#input\_opa\_tag) | OPA image tag. | `string` | `"1.10.1-debug"` | no |
| <a name="input_org_name"></a> [org\_name](#input\_org\_name) | Organization name for tagging. | `string` | n/a | yes |
| <a name="input_org_owner_email"></a> [org\_owner\_email](#input\_org\_owner\_email) | Contact email for the organization owner, used in resource tagging. | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | Private subnet IDs for ECS task networking. | `list(string)` | n/a | yes |
| <a name="input_public_access_cidrs"></a> [public\_access\_cidrs](#input\_public\_access\_cidrs) | CIDR blocks allowed to access the OPA ALB. | `list(string)` | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public\_subnet\_ids](#input\_public\_subnet\_ids) | Public subnet IDs for the OPA ALB. | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region for logging and resource configuration. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to module resources. | `map(string)` | `{}` | no |
| <a name="input_task_execution_role_arn"></a> [task\_execution\_role\_arn](#input\_task\_execution\_role\_arn) | IAM execution role ARN for ECS tasks. | `string` | n/a | yes |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | IAM task role ARN for ECS tasks. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID for ALB and security groups. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | n/a |
| <a name="output_alb_url"></a> [alb\_url](#output\_alb\_url) | n/a |
<!-- END_TF_DOCS -->
