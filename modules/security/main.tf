# GCP Secret Manager is the closest analog to Azure Key Vault's secret
# store. Two things do NOT carry over 1:1 and are documented rather
# than silently dropped:
#
#   1. Purge protection: Azure Key Vault's purge_protection_enabled
#      blocks permanent deletion during a soft-delete retention window.
#      Secret Manager has no equivalent soft-delete/purge-protection
#      concept -- a destroyed secret version is gone immediately. The
#      closest guardrail Terraform can offer is `prevent_destroy`,
#      which blocks the secret container itself from being destroyed
#      by `terraform destroy` / `terraform apply` unless the lifecycle
#      block is edited first. This is a process control, not a
#      platform-enforced retention window -- treat it as such.
#   2. Private networking: Key Vault's public_network_access_enabled
#      + network_acls default-deny has no direct Secret Manager
#      equivalent; the real analog is VPC Service Controls (an org-
#      level perimeter), which is out of scope for a single Terraform
#      root module. Tracked in the roadmap below.

resource "google_secret_manager_secret" "vault" {
  project   = var.project_id
  secret_id = "secret-${var.name_prefix}"

  replication {
    auto {}
  }

  labels = var.labels

  lifecycle {
    prevent_destroy = true
  }
}

# Grant the deploying identity permission to manage secret versions,
# equivalent in intent to Azure's "Key Vault Secrets Officer" role.
# var.deployer_principal must include the IAM member type prefix
# ("serviceAccount:" for CI, "user:" for a human), same as any
# google_*_iam_member `member` argument.
resource "google_secret_manager_secret_iam_member" "secrets_officer" {
  project   = var.project_id
  secret_id = google_secret_manager_secret.vault.secret_id
  role      = "roles/secretmanager.admin"
  member    = var.deployer_principal
}
