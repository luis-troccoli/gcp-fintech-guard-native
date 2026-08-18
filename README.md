# FinTech-Guard-Native: Modular Cloud Architecture with FinOps Guardrails

**Read this in:** [English](README.md) | [Español](README.es.md) | [Italiano](README.it.md)

[![Terraform CI/CD](https://github.com/luis-troccoli/gcp-fintech-guard-native/actions/workflows/terraform-pipeline.yml/badge.svg)](https://github.com/luis-troccoli/gcp-fintech-guard-native/actions/workflows/terraform-pipeline.yml)

## 🎯 Overview
**FinTech-Guard-Native** re-implements the same security-and-FinOps baseline as its sibling project on another major cloud, restructured into reusable Terraform modules with a FinOps guardrail, aimed at the cost-and-compliance pressure typical of a financial services workload.

## 🏗️ Architecture Diagram
![Security Architecture](assets/diagrama_arquitectura.jpg)

## 💡 What This Project Adds
* **Modular architecture:** `/modules/network`, `/modules/security`, `/modules/finops` instead of flat root-level `.tf` files — each concern is independently reviewable and reusable, which matters more as a codebase grows across teams.
* **FinOps as code:** a Billing Budget with four progressive notification thresholds (50%, 75%, 90% actual spend, plus a 100% *forecasted* alert), instead of a single late warning.
* **The same hardened baseline, carried forward:** explicit default-deny firewall rules in both directions, a Secret Manager secret with restricted IAM, and a `prevent_destroy` lifecycle guard in place of the source project's soft-delete/purge-protection window.

## 🛡️ What's Actually Implemented
* **VPC firewall, both directions:** explicit allow rules for HTTPS (443) inbound and outbound, with a deny-all catch-all on each direction, applied at the VPC level (GCP has no NSG-to-subnet association step — firewall rules attach to the network directly).
* **Secret Manager, hardened:** `roles/secretmanager.admin` scoped to a single named deployer principal (no broad project-level grant), automatic replication, and `lifecycle { prevent_destroy = true }` on the secret container.
* **FinOps budget, progressive:** four notifications instead of one — three actual-spend thresholds (50/75/90%) and one forecasted-spend threshold (100%), delivered via per-address Cloud Monitoring email notification channels, all wired through Terraform variables rather than hardcoded values.
* **No hardcoded secrets or IDs:** `billing_account_id`, `deployer_principal`, and `budget_alert_emails` are required variables with no default, supplied via `TF_VAR_*` environment variables in CI or a gitignored `terraform.tfvars` locally. See `terraform.tfvars.example`.

## ⚠️ Where This Genuinely Differs From the Source Project
Two guardrails don't have a like-for-like equivalent on this platform, and are called out here rather than quietly reproduced:

1. **Deletion protection.** The source project's Key Vault purge-protection gives a soft-delete retention window that survives even a delete call. Secret Manager has no equivalent: a destroyed secret version is gone immediately. `prevent_destroy` in this module is a Terraform-level process control (it blocks `terraform destroy`/`apply` from removing the resource unless the lifecycle block is edited first) — it is not a platform-enforced recovery window. Don't treat it as one.
2. **Private network isolation.** The source project's `public_network_access_enabled = false` + default-deny network ACLs restrict Key Vault's data plane to trusted networks. The closest GCP equivalent is an org-level VPC Service Controls perimeter, which is out of scope for a single project-level Terraform root module. Tracked below as a roadmap item, same as it was on the source platform.

## 🔍 Component Breakdown
### Root
**`main.tf`** — orchestrates the three modules below (no resource-group-equivalent container to create; `var.project_id` is assumed to already exist).
![main.tf Analysis](assets/main.png)

**`variables.tf`** — project-wide inputs, including FinOps parameters (no defaults for billing account ID, deployer principal, or alert emails, by design).
![variables.tf Analysis](assets/variables.png)

**`providers.tf`** — Terraform and `google` provider configuration.
![providers.tf Analysis](assets/providers.png)

**`outputs.tf`** — aggregates each module's outputs.
![outputs.tf Analysis](assets/outputs.png)

### `modules/network`
VPC, subnet, and four firewall rules (HTTPS allow + deny-all, both directions).
![network module Analysis](assets/network.png)

### `modules/security`
Secret Manager secret with automatic replication, restricted IAM binding, and a `prevent_destroy` lifecycle guard.
![security module Analysis](assets/security.png)

### `modules/finops`
The billing budget with progressive thresholds and per-recipient email notification channels, parameterized by billing account ID, project ID, budget amount/currency, and alert emails.
![finops module Analysis](assets/finops.png)

---

## 🛠️ Tech Stack
* **Cloud:** Google Cloud Platform (VPC, Secret Manager, Cloud Billing Budgets, Cloud Monitoring notification channels)
* **IaC:** HashiCorp Terraform (`google` provider ~> 5.0), modular structure
* **Security Scanning:** Checkov (blocking, `soft_fail: false`)
* **CI/CD:** GitHub Actions with Workload Identity Federation (no long-lived service account keys)
* **Version Control:** Git (GitHub)

## 🤖 CI/CD Pipeline
The pipeline runs, in order: Workload Identity Federation login → `terraform init` → `terraform fmt -check -recursive` → `terraform validate` → Checkov security scan (blocking) → `terraform plan` → `terraform apply` (on `main` only).

Required GitHub repo secrets: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_SERVICE_ACCOUNT`, `GCP_PROJECT_ID`, `GCP_BILLING_ACCOUNT_ID`, `BUDGET_ALERT_EMAILS`, `GCP_BUDGET_CURRENCY`.

## 📈 Roadmap
* **Org Policy:** continuous compliance monitoring, mirroring the source project's Azure Policy roadmap item.
* **VPC Service Controls:** a real network perimeter around the Secret Manager secret, closing the gap noted above.
* **Remote backend:** a GCS bucket with state locking (still pending, same gap as the source project's remote-backend roadmap item).

## 🚀 Deployment Guide
1. Copy `terraform.tfvars.example` to `terraform.tfvars` and provide your GCP project ID, billing account ID, deployer principal, and budget alert email(s).
2. `terraform init`
3. `terraform validate` / `terraform plan` — recommended before any apply, to review the exact changes.
4. `terraform apply` — in this repo, this step runs automatically via the CI/CD pipeline on every push to `main` (see below). For manual/local deployments outside of CI, run it directly against your own state.
5. `terraform destroy` when finished, to avoid unwanted costs. Note: this project does not yet use a remote state backend (see roadmap), so state is local to whichever environment ran the apply — keep local and CI runs from the same source of truth to avoid drift.

## 🤝 Contribution
Open to PRs and architecture discussion from anyone working on cloud security or FinOps.