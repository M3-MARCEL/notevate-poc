variable "aws_region" {
  description = "Región AWS — us-east-1 (Norte de Virginia) es la predeterminada en AWS Academy"
  type        = string
  default     = "us-east-1"
}

variable "azure_region" {
  description = "Región Azure — East US minimiza latencia cross-cloud hacia us-east-1"
  type        = string
  default     = "East US"
}

variable "azure_subscription_id" {
  description = "ID de suscripción Azure for Students (az account show --query id)"
  type        = string
  sensitive   = true
}

variable "project_name" {
  description = "Prefijo para nombrar todos los recursos"
  type        = string
  default     = "notevate"
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "poc"
}

variable "vpc_cidr" {
  description = "Bloque CIDR de la VPC principal"
  type        = string
  default     = "10.0.0.0/16"
}

variable "db_admin_username" {
  description = "Usuario administrador de Azure SQL Server"
  type        = string
  default     = "notevateadmin"
  sensitive   = true
}

variable "db_admin_password" {
  description = "Contraseña admin Azure SQL (mín. 8 chars, mayúsculas + números + especiales)"
  type        = string
  sensitive   = true
}

variable "backend_image" {
  description = "URI imagen Docker backend en ECR (actualizar tras primer push)"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:stable"
  # Reemplazar con: <account_id>.dkr.ecr.us-east-1.amazonaws.com/notevate/backend:latest
}

variable "dev_ip_address" {
  description = "Tu IP local para acceso de desarrollo a Azure SQL (curl ifconfig.me)"
  type        = string
  default     = "0.0.0.0"
}
