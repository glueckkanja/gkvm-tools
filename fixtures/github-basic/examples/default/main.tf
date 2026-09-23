terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
  }
}

provider "github" {}

module "this" {
  source = "../../"

  name        = "gkvm-fixture-default"
  description = "Created by the gkvm-tools fixture"
}
