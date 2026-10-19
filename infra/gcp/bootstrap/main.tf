# Run by Jean-Luc with his own user credentials. Agents can edit this, but
# can't apply it: the cloud-agents service account has no permissions outside
# the sandbox project.
#
# State is local and committed (terraform.tfstate). That is only safe because
# nothing here produces a secret -- no service account keys, no API keys. Keep
# it that way; secret-bearing resources go in ../sandbox, whose state lives in
# a private bucket.

terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
}

locals {
  project_id = "agent-sandbox-jeanlucthumm"
  # Not a secret: using it requires IAM on the billing account.
  billing_account = "018F53-E209CC-6B75F3"
}

provider "google" {}

# The budgets API requires a quota project, and user credentials have none by
# default. Scoped to the budget alone: routing every call through the sandbox
# would need each API enabled there before the first plan can even read it.
provider "google" {
  alias                 = "quota"
  user_project_override = true
  billing_project       = local.project_id
}

resource "google_project" "sandbox" {
  project_id      = local.project_id
  name            = local.project_id
  billing_account = local.billing_account
  deletion_policy = "PREVENT"
}

# Calls made with the cloud-agents key are billed to this project, so the
# basics agents (and key rotation) rely on must be enabled here.
resource "google_project_service" "bootstrap" {
  for_each = toset([
    "billingbudgets.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
  ])
  project            = google_project.sandbox.project_id
  service            = each.value
  disable_on_destroy = false
}

# The identity agents act as. Its key is minted outside Terraform so it never
# lands in state.
resource "google_service_account" "cloud_agents" {
  project    = google_project.sandbox.project_id
  account_id = "cloud-agents"
}

resource "google_project_iam_member" "cloud_agents_owner" {
  project = google_project.sandbox.project_id
  role    = "roles/owner"
  member  = google_service_account.cloud_agents.member
}

resource "google_storage_bucket" "sandbox_state" {
  project                     = google_project.sandbox.project_id
  name                        = "${local.project_id}-tfstate"
  location                    = "US"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  versioning {
    enabled = true
  }
  depends_on = [google_project_service.bootstrap]
}

# Owner can run up charges; this is the safety net. Alerts email the billing
# account admins.
resource "google_billing_budget" "sandbox" {
  provider        = google.quota
  billing_account = local.billing_account
  display_name    = "${local.project_id} monthly"
  budget_filter {
    projects = ["projects/${google_project.sandbox.number}"]
  }
  amount {
    specified_amount {
      currency_code = "USD"
      units         = "20"
    }
  }
  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }
  depends_on = [google_project_service.bootstrap]
}
