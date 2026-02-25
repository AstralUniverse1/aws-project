# Project1 – ECS Fargate + ALB (HTTPS) + RDS + CodePipeline (Terraform)

A small web service on **ECS Fargate** (private subnet) exposed via an **Application Load Balancer**.  
**NGINX** serves the landing page and proxies requests to a **Flask** app that reads a value from **RDS MySQL** and renders it in the HTML.

**Request path**
Internet → **ALB:443** → **ECS task (nginx:80)** → **app:5000 (same task ENI)** → **RDS:3306**

## Infrastructure highlights (Terraform)
- **Networking**
  - **VPC** with DNS hostnames enabled.
  - **Public subnets (2)**: host the **ALB** and the **NAT Gateway** (with an Elastic IP) and have a route table: `0.0.0.0/0 -> Internet Gateway`.
  - **Private subnets (2)**: host **ECS tasks** and **RDS** and have a route table: `0.0.0.0/0 -> NAT Gateway` (outbound only).
  - **NACLs**: restricted on public subnets (inbound 443 + ephemeral return ports; egress open).  
  - Outcome: only the **ALB** is internet-facing; private workloads can still reach AWS APIs (ECR/Secrets/CloudWatch) via NAT.


- **Security controls**
  - SG(ALB): inbound **443** from `0.0.0.0/0`.
  - SG(ECS): inbound **80** only from SG(ALB).
  - SG(RDS): inbound **3306** only from SG(ECS).
  - Secrets: MySQL password stored in **Secrets Manager**; injected into the app container using ECS **execution role** permissions.

- **Compute**
  - One ECS service (Fargate) with two containers in one task:
    - `nginx` → reverse proxy
    - `app` → Flask + MySQL query
  - In `awsvpc`, containers share the task ENI, so the correct proxy target is **`127.0.0.1:5000`**.

## CI/CD (CodeCommit → CodeBuild → ECS)
- CodeBuild builds and pushes images to ECR, tagged with:
  - commit SHA (for traceable versions) and
  - `latest` (for default “current release”)
- Pipeline deploy uses `imagedefinitions.json` to update the ECS service (new task definition revision).

## HTTPS (what was done here + how to make it “valid”)
### Current state (self-signed, works with browser warning)
1) Generate a self-signed cert (key + cert).
2) Import it into **ACM**.
3) ALB listener on **443/HTTPS** uses that ACM certificate and forwards to target group on **80/HTTP**.

### Valid HTTPS (trusted certificate)
1) Own a domain (example: `project1.yourdomain.com`).
2) Create DNS zone (Route53 or external).
3) Request **ACM public certificate** in the ALB region (`il-central-1`) with **DNS validation**.
4) Add ACM validation CNAME record(s) in DNS; wait for ACM status **Issued**.
5) Update the ALB HTTPS listener to use the **ACM-issued cert ARN**.
6) Create DNS record pointing the domain to the ALB (Route53 **Alias A/AAAA** recommended).
Result: browser shows a trusted lock (no warning).

