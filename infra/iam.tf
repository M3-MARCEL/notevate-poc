# ─── IAM — Roles y Autorización ───────────────────────────────────────────────
#
# CONTEXTO AWS Academy:
# Las cuentas AWS Academy NO permiten crear nuevos roles IAM con Terraform.
# En su lugar, se referencia el rol "LabRole" que Academy provee preconfigurado.
# En una cuenta AWS real, estos recursos se crearían con aws_iam_role.
# ─────────────────────────────────────────────────────────────────────────────

# ─── ROL PREEXISTENTE DE AWS ACADEMY ─────────────────────────────────────────
# LabRole tiene permisos para: ECS, ECR, S3, CloudWatch Logs, Secrets Manager
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ─── POLÍTICA DE ACCESO A S3 (principio de menor privilegio) ─────────────────
# Define exactamente qué puede hacer el backend sobre S3:
# solo leer/escribir en los dos buckets específicos de Notevate
resource "aws_iam_policy" "s3_backend_access" {
  name        = "${var.project_name}-s3-backend-policy"
  description = "Permite al backend ECS operar solo sobre los buckets de Notevate"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowProfilePictures"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = [
          "${aws_s3_bucket.profile_pictures.arn}/*"
        ]
      },
      {
        Sid    = "AllowExports"
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject"]
        Resource = [
          "${aws_s3_bucket.exports.arn}/*"
        ]
      },
      {
        Sid    = "AllowListBuckets"
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = [
          aws_s3_bucket.profile_pictures.arn,
          aws_s3_bucket.exports.arn
        ]
      }
    ]
  })
}

# ─── POLÍTICA DE ACCESO A CLOUDWATCH LOGS ────────────────────────────────────
# Permite al contenedor ECS escribir sus logs en CloudWatch
resource "aws_iam_policy" "ecs_logging" {
  name        = "${var.project_name}-ecs-logging-policy"
  description = "Permite a ECS escribir logs en el grupo /ecs/notevate/backend"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudWatchLogs"
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.backend.arn}:*"
    }]
  })
}

# ─── ADJUNTAR POLÍTICAS AL LABROLE ────────────────────────────────────────────
# NOTA: En AWS Academy el LabRole ya incluye estos permisos.
# En una cuenta real, estas líneas conectarían las políticas al rol custom.
# Se incluyen para documentar la arquitectura de autorización completa.

# resource "aws_iam_role_policy_attachment" "s3_access" {
#   role       = aws_iam_role.ecs_task_role.name   # En cuenta real
#   policy_arn = aws_iam_policy.s3_backend_access.arn
# }

# resource "aws_iam_role_policy_attachment" "ecs_logging" {
#   role       = aws_iam_role.ecs_task_role.name
#   policy_arn = aws_iam_policy.ecs_logging.arn
# }

# ─── OUTPUT: ARN DEL ROL ──────────────────────────────────────────────────────
output "iam_role_arn" {
  description = "ARN del rol IAM usado por las tareas ECS"
  value       = data.aws_iam_role.lab_role.arn
}

output "s3_policy_arn" {
  description = "ARN de la política de acceso a S3 (menor privilegio)"
  value       = aws_iam_policy.s3_backend_access.arn
}
