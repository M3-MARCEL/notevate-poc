# Notevate — PoC Multicloud (Evaluación 3)

Plataforma de productividad personal con arquitectura híbrida multicloud:
- **AWS**: ECS Fargate (backend), S3 (objetos), ECR (imágenes)
- **Azure**: SQL Database PaaS (base de datos)
- **IaC**: Terraform multi-provider

---

## 🚀 Pasos de despliegue

### 1. Prerequisitos
```bash
# Instalar Terraform >= 1.7
# Instalar AWS CLI + Azure CLI
az login
aws configure  # o exportar credenciales de AWS Academy
```

### 2. Infraestructura (Terraform)
```bash
cd infra/
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores

terraform init
terraform plan
terraform apply
```

### 3. Build y push del backend
```bash
# Obtener URL del ECR desde outputs de Terraform
ECR_URL=$(terraform -chdir=infra output -raw ecr_backend_url)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $ECR_URL

docker build -t notevate-backend ./backend
docker tag  notevate-backend:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### 4. Actualizar imagen en ECS
```bash
# Actualizar variable en terraform.tfvars:
# backend_image = "<ECR_URL>:latest"
terraform -chdir=infra apply

# O forzar redeploy directamente:
aws ecs update-service --cluster notevate-cluster \
  --service notevate-backend-svc --force-new-deployment
```

### 5. Verificar funcionamiento
```bash
ALB_URL=$(terraform -chdir=infra output -raw alb_url)
curl $ALB_URL/health
```

---

## 🎬 Demo de Alta Disponibilidad (para el video)

```bash
# 1. Abrir la app en el browser → funciona (tomar nota del ALB URL)
# 2. Listar tareas ECS activas
aws ecs list-tasks --cluster notevate-cluster --service-name notevate-backend-svc

# 3. Detener UNA tarea (simular fallo)
aws ecs stop-task --cluster notevate-cluster --task <TASK_ARN>

# 4. Inmediatamente hacer curl al ALB → sigue respondiendo (otra tarea en AZ-b)
curl $ALB_URL/health

# 5. ECS lanza automáticamente una nueva tarea para reemplazar la caída
aws ecs describe-services --cluster notevate-cluster --services notevate-backend-svc \
  --query 'services[0].{running:runningCount,desired:desiredCount}'
```
