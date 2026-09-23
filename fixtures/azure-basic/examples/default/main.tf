terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "this" {
  source = "../../"

  location = "westeurope"
  name     = "rg-gkvm-fixture-default"
  lock = {
    kind = "CanNotDelete"
  }
  tags = {
    origin = "gkvm-tools fixture"
  }
}
