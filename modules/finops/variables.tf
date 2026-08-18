variable "billing_account_id" {
  description = "The GCP Billing Account ID the budget applies to (format XXXXXX-XXXXXX-XXXXXX)"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID this budget monitors"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for the budget display name"
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
