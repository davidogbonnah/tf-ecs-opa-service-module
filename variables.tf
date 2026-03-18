variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string
}

variable "org_name" {
  description = "Organization name for tagging."
  type        = string
}

variable "org_owner_email" {
  description = "Contact email for the organization owner, used in resource tagging."
  type        = string
}

variable "cluster_id" {
  description = "ECS cluster ID where the OPA service is deployed."
  type        = string
}

variable "opa_repository_url" {
  description = "ECR repository URL for the OPA image."
  type        = string
}

variable "opa_service_name" {
  description = "OPA service name used for ECS and ALB resources."
  type        = string
}

variable "opa_container_port" {
  description = "Port exposed by the OPA container."
  type        = number
  default     = 8181
}

variable "opa_health_check_path" {
  description = "HTTP path used for OPA health checks."
  type        = string
  default     = "/health"
}

variable "opa_tag" {
  description = "OPA image tag."
  type        = string
  default     = "1.14.1-1"
}

variable "opa_cpu" {
  description = "CPU units for the OPA task."
  type        = number
  default     = 256
}

variable "opa_memory" {
  description = "Memory in MiB for the OPA task."
  type        = number
  default     = 512
}

variable "opa_bundle_api_url" {
  description = "URL for the OPA bundle API, passed as an environment variable to the container."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS task networking."
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the OPA ALB."
  type        = list(string)
  default     = []
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the OPA ALB."
  type        = list(string)
}

variable "region" {
  description = "AWS region for logging and resource configuration."
  type        = string
}

variable "tags" {
  description = "Tags applied to module resources."
  type        = map(string)
  default     = {}
}

variable "task_execution_role_arn" {
  description = "IAM execution role ARN for ECS tasks."
  type        = string
}

variable "task_role_arn" {
  description = "IAM task role ARN for ECS tasks."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for ALB and security groups."
  type        = string
}

variable "desired_count" {
  description = "Desired number of OPA tasks."
  type        = number
  default     = 3
}
