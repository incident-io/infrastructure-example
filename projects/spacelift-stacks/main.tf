################################################################################
# Spacelift Stacks: management of terraform pipelines
################################################################################

terraform {
  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "0.1.3"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.74.0"
    }
  }
}

# Spacelift will inject the administrative credentials, as we have configured
# the pipeline to have access:
#
# https://<your-spacelift>.app.spacelift.io/stack/spacelift-stacks
provider "spacelift" {}

# Google access will be granted via the GCP service account bound to this stack
# (see below). We should use this provider for managing projects only.
provider "google" {}

################################################################################
# projects/spacelift-stacks (us!)
################################################################################

resource "spacelift_stack" "spacelift_stacks" {
  name         = "spacelift-stacks"
  description  = "Configuration of Spacelift stacks"
  repository   = "infrastructure"
  branch       = "master"
  project_root = "projects/spacelift-stacks"

  # This stack controls other stacks:
  administrative = true

  # Always useful to locally preview
  enable_local_preview = true

  labels = [
    "admin",
  ]
}

# This service account is created in a Spacelift GCP project, and bound to our
# spacelift-stacks Stack. We should only use it to create GCP projects and
# assign IAM permissions within them.
resource "spacelift_gcp_service_account" "spacelift_stacks" {
  stack_id = spacelift_stack.spacelift_stacks.id
  token_scopes = [
    "https://www.googleapis.com/auth/cloud-platform",
  ]
}
################################################################################
# projects/todo-list
################################################################################

module "todo_list" {
  for_each = {
    "staging" = {
      project = "todolist-staging"
    }
    "production" = {
      project = "todolist-production"
    }
    "dev-lawrence" = {
      project    = "todolist-dev-lawrence"
      autodeploy = true
    }
  }

  source = "./modules/stack"

  application       = "todo-list"
  instance          = each.key
  google_project_id = each.value.project
  billing_account   = lookup(each.value, "billing_account", var.billing_account)
  org_id            = var.org_id
  autodeploy        = lookup(each.value, "autodeploy", false)
}
