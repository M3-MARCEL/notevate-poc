output "alb_url" {
  description = "URL pública del backend (punto de entrada principal)"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_backend_url" {
  description = "Repositorio ECR backend — usar en docker push"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_url" {
  description = "Repositorio ECR frontend"
  value       = aws_ecr_repository.frontend.repository_url
}

output "nat_gateway_ip" {
  description = "IP pública del NAT Gateway (configurada como regla en Azure SQL)"
  value       = aws_eip.nat.public_ip
}

output "azure_sql_fqdn" {
  description = "FQDN del servidor Azure SQL"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "s3_bucket_profiles" {
  description = "Bucket S3 para fotos de perfil"
  value       = aws_s3_bucket.profile_pictures.bucket
}

output "s3_bucket_exports" {
  description = "Bucket S3 para exportaciones PDF"
  value       = aws_s3_bucket.exports.bucket
}

output "ecs_cluster" {
  description = "Nombre del cluster ECS — para demo de alta disponibilidad"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service" {
  description = "Nombre del servicio ECS — para demo de alta disponibilidad"
  value       = aws_ecs_service.backend.name
}

output "azure_sql_connection_string" {
  description = "Cadena de conexión completa (sensible)"
  value       = "mssql+pymssql://${var.db_admin_username}:${var.db_admin_password}@${azurerm_mssql_server.main.fully_qualified_domain_name}/${azurerm_mssql_database.main.name}"
  sensitive   = true
}
