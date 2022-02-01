################################################################################
# modules/stack
#
# Generic Stack creator, assuming you want a 121 mapping between Spacelift Stack
# and Google project, with a Spacelift managed service account that can
# administrate the GCP project.
################################################################################

terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "0.1.3"
    }
  }
}

resource "spacelift_stack" "stack" {
  name         = local.stack_name_computed
  repository   = "infrastructure"
  branch       = "master"
  project_root = "projects/${var.application}"

  # Allow running terraform commands from local machines- toggle this depending
  # on the sensitivity of the Stack in future.
  enable_local_preview = true

  # Whether we should deploy on merge
  autodeploy = var.autodeploy

  # *.auto.tfvars are read automatically by terraform
  before_init = [
    "mv -v _${var.instance}.tfvars _${var.instance}.auto.tfvars",
  ]

  labels = [
    "folder:${var.application}",
  ]
}

resource "spacelift_gcp_service_account" "manager" {
  stack_id = spacelift_stack.stack.id
  token_scopes = [
    "https://www.googleapis.com/auth/compute",
    "https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/ndev.clouddns.readwrite",
    "https://www.googleapis.com/auth/devstorage.full_control",
    "https://www.googleapis.com/auth/userinfo.email",
  ]
}

resource "google_project" "project" {
  name            = var.google_project_id
  project_id      = var.google_project_id
  billing_account = var.billing_account
  org_id          = var.org_id
}

resource "google_project_iam_member" "stack_owner" {
  for_each = toset([
    # General admin over the project
    "roles/owner",
    # Permits control of GCS bucket IAMs, which is required to apply permissions
    "roles/storage.admin"
  ])

  project = google_project.project.id
  role    = each.key
  member  = "serviceAccount:${spacelift_gcp_service_account.manager.service_account_email}"
}

# These roles are granted at an organisation level. It should be used to extend
# a Stack GCP manager service account beyond just the Google Project it manages,
# such as if you need to assign permissions to access resources in other
# projects, like if you're provisioning observability infrastructure.
resource "google_organization_iam_member" "stack_owner" {
  for_each = toset(var.organisation_iam_roles)

  org_id = var.org_id
  role   = each.key
  member = "serviceAccount:${spacelift_gcp_service_account.manager.service_account_email}"
}
