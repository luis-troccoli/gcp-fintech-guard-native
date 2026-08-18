variable "project_id" { type = string }
variable "name_prefix" { type = string }
variable "labels" { type = map(string) }
variable "deployer_principal" {
  description = "IAM member managing the secret, with type prefix (e.g. \"serviceAccount:ci@PROJECT.iam.gserviceaccount.com\" or \"user:you@example.com\")"
  type        = string
}
