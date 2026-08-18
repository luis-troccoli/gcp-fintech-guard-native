# GCP has no "resource group" container -- var.project_id is the
# equivalent scoping boundary and is assumed to already exist
# (created out-of-band, e.g. via an org-level bootstrap process).

# 1. Networking Module
module "network" {
  source      = "./modules/network"
  name_prefix = var.name_prefix
  region      = var.region
}

# 2. Security Module
module "security" {
  source              = "./modules/security"
  project_id          = var.project_id
  name_prefix         = var.name_prefix
  labels              = var.labels
  deployer_principal  = var.deployer_principal
}

# 3. FinOps Module
# All values wired from variables -- no hardcoded billing account ID,
# project ID, or email placeholders.
module "finops" {
  source              = "./modules/finops"
  billing_account_id  = var.billing_account_id
  project_id          = var.project_id
  name_prefix         = var.name_prefix
  budget_amount       = var.budget_amount
  budget_currency     = var.budget_currency
  budget_alert_emails = var.budget_alert_emails
}
