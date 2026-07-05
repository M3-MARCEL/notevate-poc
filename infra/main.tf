# ─── NOTEVATE — Infraestructura como Código ───────────────────────────────────
# Terraform Multi-Provider: AWS (cómputo) + Azure (datos)
# Región AWS: us-east-1 (Norte de Virginia) — región predeterminada AWS Academy
# Región Azure: East US — menor latencia cross-cloud hacia us-east-1
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  # NOTA AWS Academy: usar backend local (las credenciales expiran ~4h;
  # el backend S3 requiere DynamoDB para locking, no disponible en Academy)
  # Para producción real: descomentar bloque backend "s3" abajo
  # backend "s3" {
  #   bucket         = "notevate-tfstate"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "notevate-tf-lock"
  # }
}

# ─── PROVIDER AWS ─────────────────────────────────────────────────────────────
# AWS Academy: exportar credenciales antes de ejecutar Terraform:
#   export AWS_ACCESS_KEY_ID=...
#   export AWS_SECRET_ACCESS_KEY=...
#   export AWS_SESSION_TOKEN=...   (requerido en Academy, expira ~4h)
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ─── PROVIDER AZURE ───────────────────────────────────────────────────────────
# Azure for Students: ejecutar `az login` antes de terraform apply
# O usar variables de entorno: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

# ─── PROVIDER RANDOM ─────────────────────────────────────────────────────────
# Para generar sufijos únicos en nombres de recursos globales (S3, SQL Server)
provider "random" {}
