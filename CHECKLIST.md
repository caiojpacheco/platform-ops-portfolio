# Pre-publish Checklist

## Local validation

### App
- [ ] `cd app && pip install -r requirements.txt`
- [ ] `cd app && pytest tests/ -v` — all tests pass
- [ ] `cd app && docker build -t platform-ops-api:test .` — builds without errors
- [ ] `cd app && docker compose up` — API responds at http://localhost:8000/health
- [ ] `curl http://localhost:8000/api/items` returns `[]`
- [ ] POST/GET/PUT/DELETE cycle on `/api/items` works correctly
- [ ] `curl http://localhost:8000/metrics` returns Prometheus metrics

### Terraform
- [ ] `cd infra/terraform && terraform init` — no errors
- [ ] `terraform validate` — "Success! The configuration is valid."
- [ ] `terraform fmt -check -recursive` — no formatting issues
- [ ] `terraform plan` (staging workspace) — plan shows expected resources

### Kubernetes
- [ ] `kubectl --dry-run=client -f k8s/ --validate=true` — all manifests valid
- [ ] No hardcoded secrets or credentials in any YAML file
- [ ] Image reference in `deployment.yaml` updated to your ECR URL

### GitHub Actions
- [ ] Replace `YOUR_USERNAME` in README.md badges with your GitHub username
- [ ] GitHub Environments configured: `staging` (auto) and `production` (manual approval)
- [ ] Secrets added to GitHub:
  - `AWS_ROLE_ARN` (CI)
  - `AWS_ROLE_ARN_STAGING`
  - `AWS_ROLE_ARN_PRODUCTION`
  - `GRAFANA_URL`
  - `GRAFANA_API_KEY`
  - `SLACK_WEBHOOK_URL`

## Security review
- [ ] `.gitignore` covers `.env`, `*.tfstate`, `*.tfvars`
- [ ] No real passwords or API keys committed
- [ ] `secret.yaml` contains only placeholder base64 values
- [ ] IAM roles follow least-privilege (no `*` actions unless justified)
- [ ] ECR images are `IMMUTABLE`
- [ ] Trivy scan configured to fail on CRITICAL/HIGH

## Before publishing on LinkedIn
- [ ] Update `YOUR_USERNAME` references in README.md
- [ ] Update `api.platform-ops.example.com` with your real domain (or leave as example)
- [ ] Verify all badges render correctly on GitHub
- [ ] Add a screenshot of the Grafana dashboard to the README (optional but impressive)
- [ ] Tag the repo: `v1.0.0`

## GitHub repository settings
- [ ] Add topics: `devops`, `kubernetes`, `terraform`, `aws`, `fastapi`, `github-actions`, `prometheus`, `grafana`
- [ ] Enable Dependabot for security alerts
- [ ] Enable branch protection on `main`:
  - Require PR reviews
  - Require status checks (CI must pass)
  - Restrict force-push
