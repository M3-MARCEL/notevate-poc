# Notevate

Aplicación de gestión de tareas con un motor de decisiones para pendientes vencidos — en vez de simplemente acumularse, las tareas vencidas te obligan a decidir: reagendarlas, dividirlas en subtareas, o descartarlas.

Nació como una exploración práctica de arquitectura multicloud: el backend corre en AWS, la base de datos vive en Azure, y el frontend se sirve desde el hosting estático de Azure — todo conectado y aprovisionado completamente con Terraform.

## Arquitectura

```
                    ┌─────────────────────────────┐
                    │      Azure Static Web Apps   │
                    │      (Frontend React)        │
                    └──────────────┬───────────────┘
                                   │ HTTPS / REST
                                   ▼
   ┌───────────────────────────────────────────────────────┐
   │                    AWS — us-east-1                     │
   │                                                          │
   │  EC2 (Nginx + Let's Encrypt) ──▶ ALB ──▶ ECS Fargate     │
   │                                          (2 AZs, 2 tasks)│
   │                                          Backend FastAPI │
   └──────────────────────┬───────────────────────────────────┘
                          │ NAT Gateway (salida)
                          ▼
                 ┌─────────────────────┐
                 │  Azure SQL Database  │
                 └─────────────────────┘
```

- **Frontend**: React, desplegado en Azure Static Web Apps
- **Backend**: FastAPI (Python), contenerizado, corriendo en AWS ECS Fargate distribuido en dos Zonas de Disponibilidad detrás de un Application Load Balancer
- **Base de datos**: Azure SQL Database, accesible desde AWS mediante una regla de firewall acotada a la IP del NAT Gateway
- **HTTPS**: como el ALB solo entrega HTTP, hay una instancia EC2 corriendo Nginx como proxy inverso con certificado Let's Encrypt (vía DuckDNS) delante de él
- **Almacenamiento de objetos**: dos buckets S3 — uno para fotos de perfil, otro para exportaciones en PDF
- **Infraestructura**: 100% Terraform, combinando los providers de AWS y Azure en un mismo proyecto

## Por qué multicloud

No porque cada pieza no pudiera vivir en un solo proveedor — es un ejercicio deliberado de hacer que dos nubes se comuniquen de forma limpia: estado de Terraform cruzando providers, una regla de firewall en Azure que referencia directamente la IP de un recurso de AWS, y una red privada de backend que sale a conectarse con una base de datos gestionada en una nube completamente distinta.

## Correrlo localmente

**Backend**
```bash
cd backend
pip install -r requirements.txt
uvicorn src.main:app --reload
```

**Frontend**
```bash
cd frontend
npm install
npm start
```

Necesitas un `.env` en `frontend/` con `REACT_APP_API_URL` apuntando a tu backend, y las variables de entorno usuales de conexión a Azure SQL para el backend (ver `backend/src/database.py`).

## Desplegar la infraestructura

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Requiere credenciales de AWS y Azure configuradas localmente, más un `terraform.tfvars` con tus propios valores (ver `variables.tf` para saber qué se espera — nada sensible queda versionado).

## Limitaciones conocidas

- El flujo de reagendar usa un `prompt()` nativo del navegador para elegir la nueva fecha — funcional, pero lejos de pulido. Un selector de fecha/hora real es el siguiente paso obvio.
- Las tareas reagendadas actualmente salen de la lista de "pendientes" en vez de reaparecer con su nueva fecha — es un tema de filtrado en el frontend, no un problema del backend.
- La configuración del proxy Nginx/Let's Encrypt vive parcialmente fuera de Terraform (parte se configuró directo por SSH), así que todavía no es 100% reproducible solo con `terraform apply`.

## Stack

Python · FastAPI · React · Docker · Terraform · AWS (ECS Fargate, ALB, NAT Gateway, S3, ECR, CloudWatch) · Azure (SQL Database, Static Web Apps) · Nginx · Let's Encrypt
