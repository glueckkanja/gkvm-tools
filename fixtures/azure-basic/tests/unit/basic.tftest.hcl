mock_provider "azurerm" {}

run "no_lock_by_default" {
  command = plan

  variables {
    location = "westeurope"
    name     = "rg-unit"
  }

  assert {
    condition     = length(azurerm_management_lock.this) == 0
    error_message = "no lock must be created unless requested"
  }
}

run "lock_when_requested" {
  command = plan

  variables {
    location = "westeurope"
    name     = "rg-unit"
    lock = {
      kind = "ReadOnly"
    }
  }

  assert {
    condition     = azurerm_management_lock.this[0].lock_level == "ReadOnly"
    error_message = "lock level must follow var.lock.kind"
  }
}
