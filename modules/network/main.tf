resource "google_compute_network" "vpc" {
  name                    = "vpc-${var.name_prefix}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "internal" {
  name                     = "internal"
  network                  = google_compute_network.vpc.id
  region                   = var.region
  ip_cidr_range            = "10.0.1.0/24"
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# GCP VPCs have no implicit allow rules between subnets (unlike Azure's
# default-allow-VNet rule), but they DO implicitly allow all egress
# unless a rule says otherwise, and there is no built-in ingress deny.
# These four rules recreate the explicit default-deny-both-directions
# posture from Phase 1/2, carried forward here on purpose.

resource "google_compute_firewall" "allow_https_inbound" {
  name      = "allow-https-inbound-${var.name_prefix}"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 100

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny_all_inbound" {
  name      = "deny-all-inbound-${var.name_prefix}"
  network   = google_compute_network.vpc.id
  direction = "INGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_https_outbound" {
  name      = "allow-https-outbound-${var.name_prefix}"
  network   = google_compute_network.vpc.id
  direction = "EGRESS"
  priority  = 100

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "deny_all_outbound" {
  name      = "deny-all-outbound-${var.name_prefix}"
  network   = google_compute_network.vpc.id
  direction = "EGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}
