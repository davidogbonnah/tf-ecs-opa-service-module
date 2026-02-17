locals {
  tags = {
    Environment  = var.environment
    Project      = "${var.org_name} Cloud Management Platform"
    Owner        = "${var.org_name} Platform Team"
    ManagedBy    = "Terraform"
    ContactEmail = var.org_owner_email
  }
}

resource "aws_cloudwatch_log_group" "opa_log_group" {
  name              = "/ecs/${var.opa_service_name}"
  retention_in_days = 14
  tags = merge(
    var.tags, local.tags,
    {
      Name = "/ecs/${var.opa_service_name}"
    }
  )
}

resource "aws_ecs_task_definition" "opa_td" {
  family                   = "${var.opa_service_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.opa_cpu
  memory                   = var.opa_memory
  execution_role_arn       = var.task_execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "${var.opa_service_name}-container"
      image     = "${var.opa_repository_url}:${var.opa_tag}"
      command   = ["run", "--server", "--config-file", "/app/config.json", "--addr=0.0.0.0:${var.opa_container_port}"]
      essential = true
      portMappings = [{
        containerPort = var.opa_container_port
        hostPort      = var.opa_container_port
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-region        = var.region
          awslogs-stream-prefix = var.opa_service_name
          awslogs-group         = aws_cloudwatch_log_group.opa_log_group.name
        }
      }
      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.opa_container_port}${var.opa_health_check_path} || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }
    }
  ])

  tags = merge(
    var.tags, local.tags,
    {
      Name = "${var.opa_service_name}-td"
    }
  )
}

resource "aws_ecs_service" "opa_service" {
  name                   = "${var.opa_service_name}-service"
  cluster                = var.cluster_id
  task_definition        = aws_ecs_task_definition.opa_td.arn
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.opa_ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.opa_tg.arn
    container_name   = "${var.opa_service_name}-container"
    container_port   = var.opa_container_port
  }

  desired_count = var.desired_count

  tags = merge(
    var.tags, local.tags,
    {
      Name = "${var.opa_service_name}-service"
    }
  )

  depends_on    = [aws_lb_listener.opa_listener]
}

resource "aws_lb" "opa_alb" {
  name                       = "${var.opa_service_name}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.opa_alb_sg.id]
  subnets                    = var.public_subnet_ids
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "opa_tg" {
  name        = "${var.opa_service_name}-tg"
  port        = var.opa_container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "opa_listener" {
  load_balancer_arn = aws_lb.opa_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.opa_tg.arn
  }
}

resource "aws_security_group" "opa_alb_sg" {
  name        = "${var.opa_service_name}-alb-sg"
  description = "Allow ALB to access OPA ECS"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags, local.tags,
    {
      Name = "${var.opa_service_name}-alb-sg"
    }
  )
}

resource "aws_security_group_rule" "opa_alb_sg_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.opa_alb_sg.id
  cidr_blocks       = var.public_access_cidrs
  description       = "Allow HTTP access from known Public IPs"
}

resource "aws_security_group_rule" "opa_alb_sg_egress_8181" {
  type                     = "egress"
  from_port                = var.opa_container_port
  to_port                  = var.opa_container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opa_alb_sg.id
  source_security_group_id = aws_security_group.opa_ecs_sg.id
  description              = "Allow outbound traffic to OPA ECS Cluster"
}

resource "aws_security_group" "opa_ecs_sg" {
  name        = "${var.opa_service_name}-ecs-sg"
  description = "Allow ECS OPA communication"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags, local.tags,
    {
      Name = "${var.opa_service_name}-ecs-sg"
    }
  )
}

resource "aws_security_group_rule" "opa_sg_ingress_8181" {
  type                     = "ingress"
  from_port                = var.opa_container_port
  to_port                  = var.opa_container_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opa_ecs_sg.id
  source_security_group_id = aws_security_group.opa_alb_sg.id
  description              = "Allow HTTP access from ALB"
}

resource "aws_security_group_rule" "opa_sg_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.opa_ecs_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow outbound traffic"
}
