# ─── RESOURCE GROUP ───────────────────────────────────────────────────────────
# Región: configurable vía var.azure_region (actualmente Brazil South,
# ajustado por disponibilidad de la suscripción académica)
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.azure_region
  tags     = { Project = var.project_name, Environment = var.environment }
}

# Sufijo único para el nombre del servidor SQL (debe ser globalmente único en Azure)
resource "random_string" "sql_suffix" {
  length  = 6
  upper   = false
  special = false
}

# ─── SERVIDOR AZURE SQL ────────────────────────────────────────────────────────
resource "azurerm_mssql_server" "main" {
  name                         = "${var.project_name}-sql-${random_string.sql_suffix.result}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.db_admin_username
  administrator_login_password = var.db_admin_password

  # PoC académica: endpoint público con firewall por IP
  # Producción: public_network_access_enabled = false + Private Endpoint en VNet
  public_network_access_enabled = true

  tags = { Project = var.project_name }
}

# ─── BASE DE DATOS ─────────────────────────────────────────────────────────────
resource "azurerm_mssql_database" "main" {
  name      = "${var.project_name}-db"
  server_id = azurerm_mssql_server.main.id
  # Basic: 5 DTUs, 2 GB — suficiente para PoC, costo mínimo (~$5 USD/mes)
  sku_name  = "Basic"
  depends_on = [azurerm_mssql_server.main]
  tags      = { Project = var.project_name }
}

# ─── REGLA FIREWALL: NAT GATEWAY AWS (pieza multicloud clave) ─────────────────
# La IP pública del NAT Gateway de AWS es el origen de todo el tráfico de ECS.
# Terraform crea esta regla en Azure usando un output de un recurso AWS:
# → Esto demuestra la integración real entre providers en Terraform multicloud.
resource "azurerm_mssql_firewall_rule" "allow_aws_nat" {
  name             = "allow-aws-nat-gateway-us-east-1"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = aws_eip.nat.public_ip   # Referencia cross-provider AWS → Azure
  end_ip_address   = aws_eip.nat.public_ip
}

# Regla para desarrollo local (agrega tu IP en terraform.tfvars)
resource "azurerm_mssql_firewall_rule" "allow_dev" {
  name             = "allow-local-development"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = var.dev_ip_address
  end_ip_address   = var.dev_ip_address
}
