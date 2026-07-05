# ─── SG: APPLICATION LOAD BALANCER ────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Permite HTTP desde internet; reenvía solo al SG de ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde cualquier origen"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "Solo hacia ECS en puerto 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  tags = { Name = "${var.project_name}-sg-alb" }
}

# ─── SG: ECS FARGATE (BACKEND) ────────────────────────────────────────────────
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-sg-ecs"
  description = "Solo acepta tráfico del ALB; salida irrestricta via NAT"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Solo desde el ALB en puerto 8000"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Salida total (hacia ECR, Azure SQL via NAT Gateway, S3)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-ecs" }
}
