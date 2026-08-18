variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "fintech"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)"
  type        = string
  default     = "prod"
}

variable "project_id" {
  description = "The GCP project ID where all resources are created"
  type        = string
}

variable "region" {
  description = "The GCP region for all resources"
  type        = string
  default     = "europe-west6"
}

variable "name_prefix" {
  description = "Prefix applied to resource names (GCP has no resource-group concept, so this plays that organizing role)"
  type        = string
  default     = "fintech-guard-native"
}

# Tagging standard for FinOps compliance (GCP labels: lowercase, [a-z0-9_-] only)
variable "labels" {
  description = "A map of labels to assign to all resources"
  type        = map(string)
  default = {
    project     = "fintech-guard-native"
    environment = "production"
    managed_by  = "terraform"
    cost_center = "fintech-core"
  }
}

# --- FinOps module inputs ---
# No default for billing_account_id: it must be supplied explicitly
# (e.g. via TF_VAR_billing_account_id or a .tfvars file that is
# gitignored), never hardcoded in version-controlled files.
variable "billing_account_id" {
  description = "The GCP Billing Account ID the FinOps budget applies to (format XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "budget_amount" {
  description = "Monthly budget ceiling in the billing account's currency"
  type        = number
  default     = 1000
}

variable "budget_currency" {
  description = "ISO 4217 currency code for the budget amount"
  type        = string
  default     = "USD"
}

variable "budget_alert_emails" {
  description = "List of email addresses to notify when budget thresholds are crossed"
  type        = list(string)
}

variable "deployer_principal" {
  description = "IAM member deploying/managing the security module, with type prefix (e.g. \"serviceAccount:ci@PROJECT.iam.gserviceaccount.com\")"
  type        = string
}
