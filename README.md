# platform-ops-portfolio

[![CI](https://github.com/YOUR_USERNAME/platform-ops-portfolio/actions/workflows/ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/platform-ops-portfolio/actions/workflows/ci.yml)
[![CD Staging](https://github.com/YOUR_USERNAME/platform-ops-portfolio/actions/workflows/cd-staging.yml/badge.svg)](https://github.com/YOUR_USERNAME/platform-ops-portfolio/actions/workflows/cd-staging.yml)
[![CD Production](https://github.com/YOUR_USERNAME/platform-ops-portfolio/actions/workflows/cd-production.yml/badge.svg)](https://github.com/YOUR_USERNAME/platform-ops-portfolio/actions/workflows/cd-production.yml)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?logo=docker&logoColor=white)](https://hub.docker.com/)

End-to-end DevOps portfolio demonstrating a **production-grade platform** on AWS:
containerised FastAPI app → IaC with Terraform → EKS orchestration → GitHub Actions CI/CD → full observability with Prometheus & Grafana.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Developer Workstation                                                       │
│  ┌──────────────────┐                                                        │
│  │  git push / PR   │                                                        │
│  └────────┬─────────┘                                                        │
└───────────┼─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  GitHub Actions                                                              │
│                                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐                   │
│  │  ci.yml      │    │ cd-staging   │    │ cd-production│                   │
│  │              │    │              │    │              │                   │
│  │ lint → test  │───▶│ PR → staging │    │ main →       │                   │
│  │ build → push │    │ auto-deploy  │    │ manual gate  │                   │
│  │ trivy scan   │    │              │    │ → prod deploy│                   │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘                   │
└─────────┼──────────────────┼──────────────────┼──────────────────────────┘
          │                  │                  │
          ▼                  ▼                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS Cloud                                                                   │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │  ECR (private registry)                                             │    │
│  │  Images tagged: sha-<commit>  (immutable)                           │    │
│  └──────────────────────────────┬──────────────────────────────────────┘    │
│                                 │                                            │
│  ┌──────────────────────────────▼──────────────────────────────────────┐    │
│  │  VPC  (10.0.0.0/16)                                                 │    │
│  │                                                                     │    │
│  │  Public Subnets ──────────────────────────────────────              │    │
│  │  │  ALB / Ingress-NGINX   │  NAT Gateways (x3 AZ)  │              │    │
│  │                                                                     │    │
│  │  Private Subnets ─────────────────────────────────────             │    │
│  │  │                                                   │             │    │
│  │  │  ┌─────────────────────────────────────────────┐ │             │    │
│  │  │  │  EKS Cluster  (Kubernetes 1.30)              │ │             │    │
│  │  │  │                                             │ │             │    │
│  │  │  │  Namespace: portfolio                       │ │             │    │
│  │  │  │  ┌─────────────────────────────────────┐   │ │             │    │
│  │  │  │  │  Deployment: platform-ops-api        │   │ │             │    │
│  │  │  │  │  replicas: 2–10  (HPA)               │   │ │             │    │
│  │  │  │  │  ┌──────────┐  ┌──────────┐          │   │ │             │    │
│  │  │  │  │  │  Pod 1   │  │  Pod 2   │  ...     │   │ │             │    │
│  │  │  │  │  │  FastAPI │  │  FastAPI │          │   │ │             │    │
│  │  │  │  │  └──────────┘  └──────────┘          │   │ │             │    │
│  │  │  │  └─────────────────────────────────────┘   │ │             │    │
│  │  │  │                                             │ │             │    │
│  │  │  │  Namespace: monitoring                      │ │             │    │
│  │  │  │  ┌───────────────┐  ┌──────────────────┐   │ │             │    │
│  │  │  │  │  Prometheus   │  │     Grafana       │   │ │             │    │
│  │  │  │  │  scrapes /    │─▶│  dashboards +     │   │ │             │    │
│  │  │  │  │  metrics      │  │  alertmanager     │   │ │             │    │
│  │  │  │  └───────────────┘  └──────────────────┘   │ │             │    │
│  │  │  └─────────────────────────────────────────────┘ │             │    │
│  │  │                                                   │             │    │
│  │  │  ┌─────────────────────────────────────────────┐ │             │    │
│  │  │  │  RDS Postgres (optional)                     │ │             │    │
│  │  │  └─────────────────────────────────────────────┘ │             │    │
│  │  └───────────────────────────────────────────────────             │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Stack

| Layer | Technology |
|---|---|
| Application | Python 3.12 · FastAPI · Uvicorn · Prometheus-client |
| Container | Docker (multi-stage Alpine) |
| Registry | Amazon ECR (immutable tags, Trivy scan) |
| IaC | Terraform 1.8 · AWS provider 5.x |
| Networking | AWS VPC · NAT Gateway · ALB |
| Orchestration | Amazon EKS 1.30 · kubectl · NGINX Ingress · cert-manager |
| Autoscaling | HPA (CPU + Memory) · Spot + On-Demand node groups |
| CI/CD | GitHub Actions · OIDC (no long-lived keys) |
| Observability | kube-prometheus-stack · Grafana · AlertManager |
| Secrets | GitHub Environments · AWS Secrets Manager (IRSA) |

---

## Pre-requisites

```bash
# CLI tools
aws --version          # >= 2.15
terraform version      # >= 1.8
kubectl version        # >= 1.29
helm version           # >= 3.14
docker --version       # >= 25
python --version       # >= 3.12
```

AWS account with permissions to create VPC, EKS, ECR, RDS, and IAM resources.

---

## Quick Start

### 1. Clone and configure

```bash
git clone https://github.com/YOUR_USERNAME/platform-ops-portfolio.git
cd platform-ops-portfolio
cp .env.example .env        # fill in your values
```

### 2. Run locally with Docker Compose

```bash
cd app
docker compose up --build
# API  → http://localhost:8000
# Prometheus → http://localhost:9090
# Grafana    → http://localhost:3000  (admin / admin)
```

### 3. Bootstrap Terraform state (once)

```bash
# Create S3 bucket and DynamoDB table for remote state
aws s3api create-bucket --bucket platform-ops-terraform-state --region us-east-1
aws s3api put-bucket-versioning \
  --bucket platform-ops-terraform-state \
  --versioning-configuration Status=Enabled
aws dynamodb create-table \
  --table-name platform-ops-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 4. Provision infrastructure (staging)

```bash
cd infra/terraform
terraform init
terraform workspace new staging
terraform plan -out=tfplan
terraform apply tfplan
```

### 5. Deploy the stack manually (first time)

```bash
# Fetch kubeconfig
aws eks update-kubeconfig --region us-east-1 --name platform-ops-staging

# Install NGINX Ingress
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Install cert-manager
helm upgrade --install cert-manager cert-manager \
  --repo https://charts.jetstack.io \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true

# Install monitoring stack
helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --values monitoring/values.yaml

# Apply app manifests
kubectl apply -f k8s/
```

---

## Directory structure

```
platform-ops-portfolio/
├── app/                          # FastAPI application
│   ├── main.py                   # API with /health, /metrics, /api/items
│   ├── Dockerfile                # Multi-stage Alpine build
│   ├── docker-compose.yml        # Local dev stack (API + Prometheus + Grafana)
│   ├── requirements.txt          # Pinned Python dependencies
│   ├── tests/
│   │   └── test_main.py          # Pytest test suite
│   └── observability/
│       └── prometheus.yml        # Local Prometheus scrape config
│
├── infra/terraform/              # Infrastructure as Code
│   ├── main.tf                   # Root module — wires all sub-modules
│   ├── variables.tf              # Input variables with validation
│   ├── outputs.tf                # Documented outputs
│   ├── backend.tf                # S3 + DynamoDB remote state
│   └── modules/
│       ├── vpc/                  # VPC, subnets, NAT, routing
│       ├── eks/                  # EKS cluster, node groups, OIDC
│       ├── ecr/                  # ECR repository + lifecycle policy
│       └── rds/                  # RDS Postgres (optional)
│
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml               # Template — never commit real values
│   ├── deployment.yaml           # Rolling update, probes, resource limits
│   ├── service.yaml              # ClusterIP
│   ├── ingress.yaml              # NGINX + TLS via cert-manager
│   ├── hpa.yaml                  # CPU + Memory autoscaling
│   ├── pdb.yaml                  # Min 1 pod always available
│   └── networkpolicy.yaml        # Ingress/egress whitelist
│
├── .github/workflows/
│   ├── ci.yml                    # lint → test → build → push → trivy
│   ├── cd-staging.yml            # Auto-deploy on PR
│   └── cd-production.yml         # Manual gate → deploy → rollback
│
├── monitoring/
│   ├── values.yaml               # kube-prometheus-stack Helm values
│   ├── alerts/
│   │   └── alertmanager-rules.yaml  # HighErrorRate, CrashLoop, Memory, Latency
│   └── dashboards/
│       └── app-dashboard.json    # Grafana dashboard (latency, errors, HPA)
│
└── README.md
```

---

## How CI/CD works

```
git push (any branch)
    └─▶ ci.yml
          ├── lint (ruff)
          ├── pytest
          ├── docker build (multi-stage)
          ├── docker push ECR  (tag: sha-<commit>)
          └── trivy scan (CRITICAL/HIGH → fail)

Pull Request → main
    └─▶ cd-staging.yml
          ├── configure AWS via OIDC (no stored keys)
          ├── kubectl set image  (versioned tag)
          ├── kubectl rollout status --timeout=5m
          ├── HTTP health check
          └── auto-rollback if health check fails

Merge to main  (after PR approved)
    └─▶ cd-production.yml
          ├── GitHub Environment approval gate (manual)
          ├── kubectl set image
          ├── Grafana deploy annotation
          ├── kubectl rollout status --timeout=10m
          ├── Health check (5 retries × 10s)
          ├── auto-rollback if fails
          └── Slack notification on failure
```

**Secrets strategy**: GitHub Actions uses OIDC to assume an AWS IAM role — no `AWS_ACCESS_KEY_ID` stored in GitHub. The IAM role has minimum required permissions (ECR push, EKS describe + update).

---

## Monitoring

| Signal | Source | Dashboard panel |
|---|---|---|
| Request rate | `http_requests_total` counter | "Request Rate" stat |
| Error rate | 5xx / total | "Error Rate" stat + alert at 5% |
| Latency p50/p95/p99 | `http_request_duration_seconds` histogram | "Latency" time-series |
| Pod CPU | `container_cpu_usage_seconds_total` | "Pod CPU" panel |
| Pod Memory | `container_memory_working_set_bytes` | "Pod Memory" panel |
| HPA replicas | `kube_horizontalpodautoscaler_status_current_replicas` | "HPA Replicas" stat |
| Deploy events | Grafana annotations (from cd-production.yml) | Vertical lines on all panels |

**AlertManager rules** (see `monitoring/alerts/alertmanager-rules.yaml`):
- `HighErrorRate` — error rate > 5% for 5 min → **critical**
- `PodCrashLooping` — > 3 restarts in 10 min → **critical**
- `HighMemoryUsage` — > 80% memory limit for 5 min → **warning**
- `HighCPUUsage` — > 85% CPU limit for 10 min → **warning**
- `HPAMaxReplicasReached` — at ceiling for 15 min → **warning**
- `HighP99Latency` — p99 > 2 s for 5 min → **warning**

---

## Estimated AWS costs (us-east-1)

| Resource | Spec | Est. monthly |
|---|---|---|
| EKS Control Plane | 1 cluster | $73 |
| EC2 On-Demand nodes | 2× t3.medium | $60 |
| EC2 Spot nodes | 1× t3.medium (avg) | $7 |
| NAT Gateways | 3× AZ | $99 |
| ECR storage | < 5 GB | $0.50 |
| RDS Postgres | db.t3.micro (optional) | $0* |
| **Total (without RDS)** | | **~$240/month** |

*Free tier: 750 h/month db.t3.micro for 12 months.

> **Cost tip**: In staging, use a single NAT Gateway (`count = 1` in vpc module) and reduce to 1 on-demand node to cut costs to ~$100/month.

---

## Next steps

- [ ] Add Helm chart for the app (replace raw manifests)
- [ ] Integrate External Secrets Operator with AWS Secrets Manager
- [ ] Add Karpenter for more granular node autoscaling
- [ ] Enable AWS GuardDuty and Security Hub
- [ ] Add Velero for EKS backup/restore
- [ ] Implement Argo CD for GitOps-style continuous delivery
- [ ] Add distributed tracing with OpenTelemetry + Jaeger/Tempo
- [ ] Configure Renovate bot for automated dependency updates

---

## License

MIT — see [LICENSE](LICENSE).
