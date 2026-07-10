# Notevate

Task management app with a built-in decision engine for overdue items — instead of just piling up, overdue tasks prompt you to reschedule, split into subtasks, or discard them.

Built as a hands-on exploration of multicloud architecture: the backend runs on AWS, the database lives on Azure, and the frontend is served from Azure's static hosting — all wired together and provisioned entirely through Terraform.

## Architecture

```
                    ┌─────────────────────────────┐
                    │      Azure Static Web Apps   │
                    │      (React frontend)        │
                    └──────────────┬───────────────┘
                                   │ HTTPS / REST
                                   ▼
   ┌───────────────────────────────────────────────────────┐
   │                    AWS — us-east-1                     │
   │                                                          │
   │  EC2 (Nginx + Let's Encrypt) ──▶ ALB ──▶ ECS Fargate     │
   │                                          (2 AZs, 2 tasks)│
   │                                          FastAPI backend │
   └──────────────────────┬───────────────────────────────────┘
                          │ NAT Gateway (outbound)
                          ▼
                 ┌─────────────────────┐
                 │  Azure SQL Database  │
                 └─────────────────────┘
```

- **Frontend**: React, deployed to Azure Static Web Apps
- **Backend**: FastAPI (Python), containerized, running on AWS ECS Fargate across two Availability Zones behind an Application Load Balancer
- **Database**: Azure SQL Database, reachable from AWS through a firewall rule scoped to the NAT Gateway's IP
- **HTTPS**: since the ALB only terminates HTTP, a small EC2 instance runs Nginx as a reverse proxy with a Let's Encrypt certificate (via DuckDNS) in front of it
- **Object storage**: two S3 buckets — one for profile pictures, one for PDF exports
- **Infrastructure**: 100% Terraform, spanning both the AWS and Azure providers in a single project

## Why multicloud

Not because any single piece of this couldn't live on one provider — it's a deliberate exercise in making two clouds talk to each other cleanly: cross-provider Terraform state, a firewall rule that references an AWS resource's IP directly from the Azure side, and a private backend network that reaches out to a managed database in a completely different cloud.

## Running it locally

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

You'll need a `.env` in `frontend/` pointing `REACT_APP_API_URL` at your backend, and the usual Azure SQL connection details as environment variables for the backend (see `backend/src/database.py`).

## Deploying the infrastructure

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Requires AWS and Azure credentials configured locally, plus a `terraform.tfvars` with your own values (see `variables.tf` for what's expected — nothing sensitive is committed).

## Known limitations

- The reschedule flow uses a plain browser `prompt()` for picking a new date — functional, but far from polished. A proper date picker with time selection is the obvious next step.
- Rescheduled tasks currently drop out of the "pending" list instead of reappearing with their new due date — a filtering quirk in the frontend rather than a backend issue.
- The Nginx/Let's Encrypt proxy setup lives partly outside Terraform (some of it was configured directly over SSH), so it's not fully reproducible from `terraform apply` alone yet.

## Stack

Python · FastAPI · React · Docker · Terraform · AWS (ECS Fargate, ALB, NAT Gateway, S3, ECR, CloudWatch) · Azure (SQL Database, Static Web Apps) · Nginx · Let's Encrypt
