# ─── SG: APPLICATION LOAD BALANCER ────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-sg-alb"
  description = "Permite HTTP desde internet; reenvia solo al SG de ECS"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP desde cualquier origen"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
  description = "Salida libre hacia targets (ECS)"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

  tags = { Name = "${var.project_name}-sg-alb" }
}

# ─── SG: ECS FARGATE (BACKEND) ────────────────────────────────────────────────
# CORRECCIÓN: usa security_groups (no cidr_blocks) para restringir SOLO al ALB
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-sg-ecs"
  description = "Solo acepta trafico del ALB; salida irrestricta via NAT"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Puerto 8000 exclusivamente desde el Security Group del ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    # IMPORTANTE: security_groups en vez de cidr_blocks
    # Esto garantiza que el backend NO es accesible directamente desde internet,
    # solo a traves del ALB. Principio de menor superficie de red.
  }

  egress {
    description = "Salida libre (hacia ECR, Azure SQL via NAT Gateway, S3)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg-ecs" }
}
