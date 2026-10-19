# The project, service account and Owner binding were created by hand with
# gcloud. These adopt them on the first apply; delete this file afterwards.

import {
  to = google_project.sandbox
  id = "agent-sandbox-jeanlucthumm"
}

import {
  to = google_service_account.cloud_agents
  id = "projects/agent-sandbox-jeanlucthumm/serviceAccounts/cloud-agents@agent-sandbox-jeanlucthumm.iam.gserviceaccount.com"
}

import {
  to = google_project_iam_member.cloud_agents_owner
  id = "agent-sandbox-jeanlucthumm roles/owner serviceAccount:cloud-agents@agent-sandbox-jeanlucthumm.iam.gserviceaccount.com"
}
