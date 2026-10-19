# Run by agents as the cloud-agents service account (credentials come from
# GOOGLE_APPLICATION_CREDENTIALS on the server). Everything inside the sandbox
# project lives here: APIs, API keys, IAM.
#
# State is in a private bucket created by ../bootstrap, because resources like
# API keys put their secret values in state.

terraform {
  required_version = ">= 1.8"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
  }
  backend "gcs" {
    bucket = "agent-sandbox-jeanlucthumm-tfstate"
    prefix = "sandbox"
  }
}

provider "google" {
  project = "agent-sandbox-jeanlucthumm"
}
