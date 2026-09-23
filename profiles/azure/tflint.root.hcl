# gkvm azure profile, root scope. Base rules first, AVM ruleset below.
# Kept in line with the AVM ruleset the GKVM modules were born with; the
# AVM-only structural rules (variable/output file separation, ordering) are
# enforced by avmfix in 'gkvm fix' instead of by a tflint plugin.

config {
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  version = "0.15.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "recommended"
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_lookup" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_empty_list_equality" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_module_version" {
  enabled = true
  exact   = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_unused_required_providers" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

# --- Azure Verified Modules ruleset (Azure/tflint-ruleset-avm v1) ------------
# Rule names follow the v1 renaming. Rules that AVM introduced or tightened
# after the GKVM fleet was written run at severity "notice": they are reported
# but do not fail the check (failure threshold is "warning"). Raise them to
# "error" per repository through .gkvm/tflint.root.override.hcl once the
# module complies.

plugin "avm" {
  enabled   = true
  version   = "1.1.0"
  source    = "github.com/Azure/tflint-ruleset-avm"
  signature = "attestation"
}

# Enforced: the fleet already complies (parity with the pre-v1 AVM config).
rule "avm_terraform_module_source_required" {
  enabled = true
}

rule "avm_output_resource_id_required" {
  enabled = true
}

rule "avm_interface_customer_managed_key" {
  enabled = true
}

rule "avm_interface_diagnostic_settings" {
  enabled = true
}

rule "avm_interface_location" {
  enabled = true
}

rule "avm_interface_lock" {
  enabled = true
}

rule "avm_interface_managed_identities" {
  enabled = true
}

rule "avm_interface_role_assignments" {
  enabled = true
}

rule "avm_interface_tags" {
  enabled = true
}

rule "avm_terraform_configuration_file_required" {
  enabled = true
}

rule "avm_terraform_ignore_changes_unquoted_references" {
  enabled = true
}

rule "avm_terraform_literal_heredoc_disallowed" {
  enabled = true
}

rule "avm_terraform_provider_block_disallowed" {
  enabled = true
}

rule "avm_terraform_sensitive_variable_default_disallowed" {
  enabled = true
}

rule "avm_azapi_replace_triggers_refs_valid" {
  enabled = true
}

rule "avm_provider_azurerm_version_constraint" {
  enabled = true
}

rule "avm_provider_azapi_version_constraint" {
  enabled = true
}

# Reported only: newer than the fleet. Promote per repository.
rule "avm_interface_private_endpoints" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_private_endpoints_manage_dns_zone_group" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_ignore_body_changes" {
  enabled  = true
  severity = "notice"
}

rule "avm_azapi_response_export_values_required" {
  enabled  = true
  severity = "notice"
}

rule "avm_azapi_data_response_export_values_required" {
  enabled  = true
  severity = "notice"
}

rule "avm_azapi_resource_tags_required" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_resource_tags" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_resource_types" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_retry" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_timeouts" {
  enabled  = true
  severity = "notice"
}

rule "avm_output_entire_resource_disallowed" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_lock_deprecated" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_private_endpoints_deprecated" {
  enabled  = true
  severity = "notice"
}

rule "avm_interface_role_assignments_deprecated" {
  enabled  = true
  severity = "notice"
}

# Policy, not adoption: GKVM modules use azurerm and ship no Microsoft
# telemetry (modtm dropped 2026-09).
rule "avm_provider_azurerm_disallowed" {
  enabled = false
}

rule "avm_provider_modtm_version_constraint" {
  enabled = false
}
