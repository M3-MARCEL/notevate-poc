# ─── LABROLE (AWS Academy) ────────────────────────────────────────────────────
# AWS Academy NO permite crear roles IAM nuevos via Terraform.
# Se usa el LabRole preexistente como execution_role y task_role.
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ─── CLOUDWATCH LOG GROUP ─────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}/backend"
  retention_in_days = 7
  tags              = { Name = "${var.project_name}-logs-backend" }
}

# ─── ECS CLUSTER ──────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = { Name = "${var.project_name}-cluster" }
}

# ─── TASK DEFINITION ──────────────────────────────────────────────────────────
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = var.backend_image
    essential = true

    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]

    # Variables de entorno inyectadas desde outputs de Terraform
    # NOTA PoC: En producción usar AWS Secrets Manager para credenciales
    environment = [
      { name = "ENVIRONMENT",          value = "production" },
      { name = "AWS_REGION",           value = var.aws_region },
      { name = "S3_BUCKET_PROFILES",   value = aws_s3_bucket.profile_pictures.bucket },
      { name = "S3_BUCKET_EXPORTS",    value = aws_s3_bucket.exports.bucket },
      { name = "AZURE_SQL_SERVER",     value = azurerm_mssql_server.main.fully_qualified_domain_name },
      { name = "AZURE_SQL_DB",         value = azurerm_mssql_database.main.name },
      { name = "AZURE_SQL_USER",       value = var.db_admin_username },
      { name = "AZURE_SQL_PASS",       value = var.db_admin_password },
      { name = "JWT_SECRET",           value = random_password.jwt_secret.result },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.backend.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "backend"
      }
    }

    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
      interval    = 10
      timeout     = 5
      retries     = 2
      startPeriod = 30
    }
  }])

  tags = { Name = "${var.project_name}-task-backend" }
}

# JWT secret aleatorio generado por Terraform
resource "random_password" "jwt_secret" {
  length  = 32
  special = true
}

# ─── ECS SERVICE (ALTA DISPONIBILIDAD) ───────────────────────────────────────
# 2 tareas distribuidas entre us-east-1a y us-east-1b
resource "aws_ecs_service" "backend" {
  name            = "${var.project_name}-backend-svc"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2         # Mínimo 2 tareas para tolerancia a fallos
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false   # Subredes privadas — sin IP pública directa
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 8000
  }

  # Rolling update: mantiene disponibilidad durante despliegues
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  depends_on = [aws_lb_listener.http, aws_cloudwatch_log_group.backend]
  tags       = { Name = "${var.project_name}-ecs-service" }
}

# ─── AUTO SCALING ─────────────────────────────────────────────────────────────
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_up" {
  name               = "${var.project_name}-scale-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 70.0    # Escala cuando CPU > 70%
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
