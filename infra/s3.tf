# Sufijo aleatorio para garantizar nombres de bucket globalmente únicos
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ─── BUCKET: FOTOS DE PERFIL ──────────────────────────────────────────────────
resource "aws_s3_bucket" "profile_pictures" {
  bucket = "${var.project_name}-profiles-${random_id.bucket_suffix.hex}"
  tags   = { Name = "${var.project_name}-profiles" }
}

# ─── BUCKET: EXPORTACIONES PDF ────────────────────────────────────────────────
resource "aws_s3_bucket" "exports" {
  bucket = "${var.project_name}-exports-${random_id.bucket_suffix.hex}"
  tags   = { Name = "${var.project_name}-exports" }
}

# Bloquear acceso público en ambos buckets
resource "aws_s3_bucket_public_access_block" "profiles" {
  bucket                  = aws_s3_bucket.profile_pictures.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Eliminar exportaciones PDF automáticamente a los 7 días
resource "aws_s3_bucket_lifecycle_configuration" "exports" {
  bucket = aws_s3_bucket.exports.id
  rule {
    id     = "auto-delete-exports"
    status = "Enabled"
    expiration { days = 7 }
  }
}
