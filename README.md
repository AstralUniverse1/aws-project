# AWS ECS Fargate Project

Terraform-provisioned AWS deployment of a small web service on ECS Fargate, exposed through an HTTPS Application Load Balancer and backed by RDS MySQL.

The project also includes AWS-native CI/CD with CodeCommit, CodeBuild, CodePipeline, ECR, and ECS deployment through `imagedefinitions.json`.

## Repository Structure

| Path | Purpose |
| --- | --- |
| `app/` | Flask application and app Dockerfile |
| `nginx/` | NGINX reverse proxy config and Dockerfile |
| `infra/` | Terraform infrastructure for networking, ECS, ALB, RDS, IAM, and CI/CD integration |
| `buildspec.yml` | CodeBuild steps for building, tagging, pushing, and producing the ECS deploy artifact |

## External Prerequisites

| Resource | Expected setup |
| --- | --- |
| Terraform backend | S3 bucket and DynamoDB lock table |
| Source repository | CodeCommit repo |
| Image repositories | ECR repos for the app and NGINX images |

## Application Flow

```text
Internet
→ ALB:443 HTTPS
→ ECS task: nginx:80
→ app:5000 on localhost inside the same task ENI
→ RDS MySQL:3306
```

NGINX acts as the public-facing container inside the ECS task and reverse-proxies requests to the Flask app on `127.0.0.1:5000`.

The Flask app bootstraps and reads the `app_config` table in RDS, then renders a small HTML response with the database value and build version injected during image build.

## Infrastructure

| Area | Details |
| --- | --- |
| Networking | VPC with two public subnets, two private subnets, Internet Gateway, NAT Gateway, and route tables |
| Load balancing | Public ALB across the public subnets, listening on HTTPS `443` |
| Compute | ECS Fargate service running one task with `nginx` and `app` containers |
| Database | Private RDS MySQL instance in a private DB subnet group |
| Secrets | Random MySQL password stored in Secrets Manager and injected into the app container |
| Logging | ECS containers use the CloudWatch Logs driver |
| Artifact storage | S3 bucket for CodePipeline artifacts with versioning, encryption, and public access block |

## Network Access

| Component | Access |
| --- | --- |
| ALB | Inbound `443` from the internet |
| ECS task | Inbound `80` only from the ALB security group |
| RDS MySQL | Inbound `3306` only from the ECS task security group |
| Private subnets | No direct Internet Gateway route; outbound traffic uses the NAT Gateway in a public subnet |
| Public NACL | Allows inbound HTTPS and ephemeral return traffic |

Only the ALB is internet-facing. ECS tasks and RDS have no public access; private subnet outbound traffic is routed through NAT.

## CI/CD Pipeline

| Stage | Service | Details |
| --- | --- | --- |
| Source | CodeCommit | Reads from the `main` branch |
| Build | CodeBuild | Builds the app and NGINX images, tags them, pushes to ECR, and writes `imagedefinitions.json` |
| Deploy | CodePipeline ECS action | Uses `imagedefinitions.json` to update the ECS service with a new task definition revision |

CodeBuild injects the image tag into the Flask image as `APP_VERSION`, so the deployed page shows the running build version.

Terraform task definitions default to `:latest`; pipeline deployments replace those images through `imagedefinitions.json`.

The pipeline is manual by default. An optional EventBridge trigger can be enabled for CodeCommit pushes.

## HTTPS

Terraform creates a self-signed certificate and imports it into ACM for the ALB HTTPS listener.

This enables HTTPS for the demo, but browsers will show a certificate warning. Trusted HTTPS would require a real domain and an ACM public certificate validated through DNS.
