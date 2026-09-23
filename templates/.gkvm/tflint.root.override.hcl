# Optional. Merged over the profile's tflint.root.hcl with hclmerge
# (override semantics, like Terraform override files). Same for
# tflint.module.override.hcl and tflint.example.override.hcl.
#
# Example: promote a reported-only AVM rule to blocking once the module complies.
# rule "avm_interface_retry" {
#   enabled  = true
#   severity = "error"
# }
