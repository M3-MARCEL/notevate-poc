# ─── IAM — Roles y Autorizacion ───────────────────────────────────────────────
#
# CONTEXTO AWS Academy:
# Las cuentas AWS Academy NO permiten crear nuevos roles ni policies IAM con Terraform.
# Se usa el rol preexistente "LabRole".
# ─────────────────────────────────────────────────────────────────────────────

# ─── ROL PREEXISTENTE DE AWS ACADEMY ─────────────────────────────────────────
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ─────────────────────────────────────────────────────────────────────────────
# ❌ DESHABILITADO: AWS Academy no permite crear IAM Policies
# ─────────────────────────────────────────────────────────────────────────────

# resource "aws_iam_policy" "s3_backend_access" {
#   name        = "${var.project_name}-s3-backend-policy"
#   description = "Permite al backend ECS operar solo sobre los buckets de Notevate"
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "AllowProfilePictures"
#         Effect = "Allow"
#         Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
#         Resource = [
#           "${aws_s3_bucket.profile_pictures.arn}/*"
#         ]
#       },
#       {
#         Sid    = "AllowExports"
#         Effect = "Allow"
#         Action = ["s3:GetObject", "s3:PutObject"]
#         Resource = [
#           "${aws_s3_bucket.exports.arn}/*"
#         ]
#       },
#       {
#         Sid    = "AllowListBuckets"
#         Effect = "Allow"
#         Action = ["s3:ListBucket"]
#         Resource = [
#           aws_s3_bucket.profile_pictures.arn,
#           aws_s3_bucket.exports.arn
#         ]
#       }
#     ]
#   })
# }

# resource "aws_iam_policy" "ecs_logging" {
#   name        = "${var.project_name}-ecs-logging-policy"
#   description = "Permite a ECS escribir logs en CloudWatch"
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Sid    = "AllowCloudWatchLogs"
#       Effect = "Allow"
#       Action = [
#         "logs:CreateLogStream",
#         "logs:PutLogEvents"
#       ]
#       Resource = "${aws_cloudwatch_log_group.backend.arn}:*"
#     }]
#   })
# }

# ─── OUTPUT: ARN DEL ROL ──────────────────────────────────────────────────────
output "iam_role_arn" {
  description = "ARN del rol IAM usado por las tareas ECS"
  value       = data.aws_iam_role.lab_role.arn
}

# ❌ IMPORTANTE: este output también debe eliminarse o comentarse
# porque depende de un recurso que ya no existe

# output "s3_policy_arn" {
#   description = "ARN de la politica de acceso a S3"
#   value       = aws_iam_policy.s3_backend_access.arn
# }