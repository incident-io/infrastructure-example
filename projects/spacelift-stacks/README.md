# Spacelift Stacks

Use Spacelift to manage itself, allowing us to limit administrative changes into
a single privileged environment.

This stack can be configured in the Spacelift UI, for those with an owner role
in the GitHub organisation:

- `https://<your-spacelift>.app.spacelift.io/stack/spacelift-stacks`

See the Spacelift terraform provider docs here:

- https://registry.terraform.io/providers/spacelift-io/spacelift/latest/docs

## Golden Pattern

This terraform project aims to enforce consistency around how we provision new
Google projects and environments.

We do this by applying the same pattern for each project-environment pair:

1. Create a new Spacelift Stack
2. Have Spacelift create a Google service account that is attached to (1)
3. Create a new Google project that will contain the environment
4. Assign the GCP project owner role in (3) to the account from (2)

The result is each environment has its own Spacelift Stack, with a single
project owner that can create resources within the new GCP project.

It's worth noting that the GCP service account for the spacelift-stacks Stack
retains ownership over all the projects that it creates. We can't remove this
without also removing its ability to destroy the projects, but we mitigate the
security risk by limiting the scopes Spacelift requests when provisioning the
temporary access token.
