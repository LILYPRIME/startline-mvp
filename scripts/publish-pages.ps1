param(
  [string]$Branch = "gh-pages"
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

$remote = (& git remote get-url origin 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or -not $remote) {
  throw "GitHub remote origin is not set."
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("startline-pages-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

try {
  $siteFiles = @(
    "index.html",
    "manifest.webmanifest",
    "icon.svg",
    "service-worker.js"
  )

  foreach ($file in $siteFiles) {
    Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $tempRoot $file) -Force
  }

  New-Item -ItemType File -Force -Path (Join-Path $tempRoot ".nojekyll") | Out-Null

  Push-Location $tempRoot
  try {
    Invoke-Git init
    Invoke-Git checkout -B $Branch
    Invoke-Git config user.name "StartLine Auto Backup"
    Invoke-Git config user.email "startline-auto-backup@users.noreply.github.com"
    Invoke-Git add .
    Invoke-Git commit -m ("deploy pages " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
    Invoke-Git remote add origin $remote
    Invoke-Git push origin $Branch --force
    Write-Host "Published static site to $Branch."
  } finally {
    Pop-Location
  }
} finally {
  Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

