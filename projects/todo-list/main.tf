################################################################################
# Todo List
################################################################################

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.74.0"
    }
  }
}

# Spacelift provides one-time-use Google credentials during the CI run. Default
# all Google resources into the environment's Google project.
provider "google" {
  region  = var.region
  project = var.project
}

################################################################################
# Google Project
################################################################################

data "google_project" "project" {}

resource "google_project_service" "services" {
  for_each = toset([
    # Core resources
    "iam",
    # Application message bus
    "pubsub",
    # Long-term events storage
    "bigquery",
    # Blob storage, for asset caching
    "storage",
    # StackDriver logging and metrics
    "monitoring",
    # Cloud Trace, for distributed tracing
    "cloudtrace",
    # Cloud Logging, for StackDrivers
    "logging",
    # Calendar support, for auto-call links
    "calendar-json",
  ])
  service = "${each.key}.googleapis.com"
}

################################################################################
# IAM
################################################################################

locals {
  application_roles = [
    # The app will push data into the events BigQuery dataset, and create tables
    # under it.
    "roles/bigquery.admin",
    # Permit the app to report telemetry to Google
    "roles/cloudtrace.agent",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    # Create and operate Pub/Sub resources, as the app manages provisioning of
    # new topics/subscriptions if they're missing.
    "roles/pubsub.admin",
  ]
}

############################################################
# Human access
############################################################

# Everyone in the engineering group should be able to do whatever the app can
# (for local development) plus project editor, in case they need to recover
# something via the Cloud Console.
resource "google_project_iam_member" "engineering" {
  for_each = toset(
    concat(local.application_roles, ["roles/editor"])
  )

  role   = each.key
  member = "group:engineering-team@example.com"
}

############################################################
# Application
############################################################

# Primary service account used by the app
resource "google_service_account" "app" {
  account_id   = "todo-list"
  display_name = "Todo List"
  description  = "GCP service account for Todo List"
}

# Configure all application permissions here- this should be the sum of all
# permissions required to run todo-list.
resource "google_project_iam_member" "app" {
  for_each = toset(
    local.application_roles
  )

  role   = each.key
  member = "serviceAccount:${google_service_account.app.email}"
}

################################################################################
# BigQuery
################################################################################

# Long-term storage of events, with the app managing tables inside of this
# dataset. Permissions are granted via a project IAM.
resource "google_bigquery_dataset" "events" {
  dataset_id = "events"
  location   = "EU"
  depends_on = [
    google_project_service.services["bigquery"],
  ]
}
