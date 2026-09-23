mock_provider "github" {}

run "defaults" {
  command = plan

  variables {
    name = "unit-test"
  }

  assert {
    condition     = github_repository.this.visibility == "private"
    error_message = "visibility must default to private"
  }
}

run "rejects_unknown_visibility" {
  command = plan

  variables {
    name       = "unit-test"
    visibility = "secret"
  }

  expect_failures = [var.visibility]
}
