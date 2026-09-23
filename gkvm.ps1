<#
.SYNOPSIS
  Run a gkvm-tools make target against the current module repository.
.EXAMPLE
  .\gkvm.ps1 pre-commit
  .\gkvm.ps1 pr-check
#>
param(
  [Parameter(Mandatory = $true, Position = 0)][string] $Target
)
$ErrorActionPreference = 'Stop'

if ($env:GKVM_IN_CONTAINER) {
  $home_ = if ($env:GKVM_HOME) { $env:GKVM_HOME } else { '/opt/gkvm' }
  & make --no-print-directory -f "$home_/Makefile" $Target
  exit $LASTEXITCODE
}

$runtime = if ($env:CONTAINER_RUNTIME) { $env:CONTAINER_RUNTIME } else { 'docker' }
$image   = if ($env:GKVM_IMAGE) { $env:GKVM_IMAGE } else { 'ghcr.io/glueckkanja/gkvm-tools:v0' }
$azcfg   = if ($env:AZURE_CONFIG_DIR) { $env:AZURE_CONFIG_DIR } else { Join-Path $HOME '.azure' }
New-Item -ItemType Directory -Force -Path $azcfg | Out-Null

$passthrough = @(
  'GKVM_BINARY', 'GKVM_PROFILE', 'GKVM_E2E', 'GKVM_EXAMPLE', 'GKVM_ZIZMOR_PERSONA',
  'ARM_CLIENT_ID', 'ARM_CLIENT_SECRET', 'ARM_TENANT_ID', 'ARM_SUBSCRIPTION_ID', 'ARM_USE_OIDC', 'ARM_USE_AZUREAD',
  'GITHUB_TOKEN', 'GH_TOKEN', 'GITHUB_OWNER', 'GITHUB_REPOSITORY'
)
$envArgs = @()
foreach ($name in $passthrough) {
  if (Test-Path "env:$name") { $envArgs += @('-e', $name) }
}

& $runtime run --rm -it `
  -v "${PWD}:/src" -w /src `
  -v "${azcfg}:/azureconfig" -e AZURE_CONFIG_DIR=/azureconfig `
  @envArgs `
  $image gkvm $Target
exit $LASTEXITCODE
