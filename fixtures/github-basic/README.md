<!-- BEGIN_TF_DOCS -->
# gkvm-tools fixture: github-basic

Minimal `integrations/github` module used to self-test the gkvm-tools image. Not a published module.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_github"></a> [github](#requirement\_github) (~> 6.13)

## Resources

The following resources are used by this module:

- [github_repository.this](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: Name of the repository.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_description"></a> [description](#input\_description)

Description: Optional description shown on the repository page.

Type: `string`

Default: `null`

### <a name="input_visibility"></a> [visibility](#input\_visibility)

Description: Repository visibility: public, private or internal.

Type: `string`

Default: `"private"`

## Outputs

The following outputs are exported:

### <a name="output_full_name"></a> [full\_name](#output\_full\_name)

Description: The owner/name slug of the repository.

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: The node id of the repository.

## Modules

No modules.

<!-- END_TF_DOCS -->