# =========================================================
# ECS CLUSTER
# =========================================================

resource "aws_ecs_cluster" "app" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}


# =========================================================
# APPLICATION LOAD BALANCER
# =========================================================

resource "aws_lb" "app" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.alb.id
  ]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}


# =========================================================
# TARGET GROUP
# =========================================================

resource "aws_lb_target_group" "app" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}


# =========================================================
# ALB LISTENER
# =========================================================

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}


# =========================================================
# ECS TASK DEFINITION
# =========================================================

resource "aws_ecs_task_definition" "app" {
  family = "${var.project_name}-task"

  network_mode = "awsvpc"

  requires_compatibilities = [
    "FARGATE"
  ]

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = templatefile(
    "${path.module}/../task-definition.json",
    {
      image             = "${aws_ecr_repository.app.repository_url}:latest"
      container_name    = var.project_name
      container_port    = var.container_port
      log_group         = aws_cloudwatch_log_group.app.name
      aws_region        = var.aws_region
    }
  )

  tags = {
    Name = "${var.project_name}-task"
  }
}


# =========================================================
# ECS SERVICE
# =========================================================

resource "aws_ecs_service" "app" {
  name = "${var.project_name}-service"

  cluster = aws_ecs_cluster.app.id

  task_definition = aws_ecs_task_definition.app.arn

  desired_count = var.desired_count

  launch_type = "FARGATE"

  platform_version = "LATEST"

  enable_ecs_managed_tags = true

  health_check_grace_period_seconds = 60

  network_configuration {
    subnets = [
      aws_subnet.public_a.id,
      aws_subnet.public_b.id
    ]

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn

    container_name = var.project_name

    container_port = var.container_port
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution
  ]

  tags = {
    Name = "${var.project_name}-service"
  }
}