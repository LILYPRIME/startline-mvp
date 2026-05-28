param(
  [Parameter(Mandatory = $true)]
  [string]$RepoUrl
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
Set-Location $root

function Invoke-Git {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$GitArgs
  )

  & git @GitArgs
  if ($LASTEXITCODE -ne 0) {
    throw "git $($GitArgs -join ' ') failed."
  }
}

$insideOwnWorkTree = $false
try {
  $topLevel = (& git rev-parse --show-toplevel 2>$null).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "not inside git"
  }
  $topFull = [System.IO.Path]::GetFullPath($topLevel).TrimEnd([char[]]@("\", "/"))
  $rootFull = [System.IO.Path]::GetFullPath($root).TrimEnd([char[]]@("\", "/"))
  $insideOwnWorkTree = ($topFull -eq $rootFull)
} catch {
  $insideOwnWorkTree = $false
}

if (-not $insideOwnWorkTree) {
  Invoke-Git init
  Invoke-Git branch -M main
}

$remoteExists = $true
try {
  & git remote get-url origin *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "remote not found"
  }
} catch {
  $remoteExists = $false
}

if ($remoteExists) {
  Invoke-Git remote set-url origin $RepoUrl
} else {
  Invoke-Git remote add origin $RepoUrl
}

Invoke-Git push -u origin main --tags
Write-Host "GitHub sync is connected: $RepoUrl"
