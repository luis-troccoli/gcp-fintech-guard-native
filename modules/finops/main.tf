# Billing Budget with progressive alert thresholds. GCP budgets have
# no separate "start date" input the way Azure's consumption budget
# does -- a budget is ongoing against the linked billing account from
# creation onward, scoped here to a single project via budget_filter.
#
# Email delivery: google_billing_budget doesn't take raw email
# addresses directly. Each address is wired to a Cloud Monitoring
# notification channel (type "email"), then the budget's
# all_updates_rule references those channels -- this is the
# Terraform-supported path to the same multi-recipient alerting
# Azure's contact_emails gave us directly.

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_monitoring_notification_channel" "budget_email" {
  for_each     = toset(var.budget_alert_emails)
  display_name = "budget-alert-${each.value}"
  type         = "email"

  labels = {
    email_address = each.value
  }
}

resource "google_billing_budget" "budget" {
  billing_account = var.billing_account_id
  display_name    = "budget-${var.name_prefix}"

  # The Billing Budgets API requires the numeric project number here,
  # not the project ID string -- passing the ID directly causes a
  # 400 Invalid Argument at creation time. It also requires exactly
  # one of calendar_period or custom_period to be set explicitly;
  # there is no default, and omitting it is a separate cause of the
  # same generic 400 error.
  budget_filter {
    projects        = ["projects/${data.google_project.current.number}"]
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.75
    spend_basis       = "CURRENT_SPEND"
  }

  threshold_rules {
    threshold_percent = 0.9
    spend_basis       = "CURRENT_SPEND"
  }

  # Forecasted notification: warns based on projected spend, not just
  # actual spend already incurred -- catches overruns earlier.
  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [
      for c in google_monitoring_notification_channel.budget_email : c.id
    ]
    disable_default_iam_recipients = false
  }
}