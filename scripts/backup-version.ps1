param(
  [ValidatePattern('^\d+\.\d+\.\d+$')]
  [string]$Version,

  [ValidateSet("patch", "minor", "major")]
  [string]$Bump = "patch",

  [string]$Message,

  [switch]$NoPush
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

function Get-CurrentVersion {
  if (Test-Path "VERSION") {
    $value = (Get-Content "VERSION" -Raw).Trim()
    if ($value -match '^\d+\.\d+\.\d+$') {
      return $value
    }
  }

  if (Test-Path "package.json") {
    $pkg = Get-Content "package.json" -Raw | ConvertFrom-Json
    if ($pkg.version -match '^\d+\.\d+\.\d+$') {
      return $pkg.version
    }
  }

  return "0.1.0"
}

function Get-NextVersion([string]$Current, [string]$BumpKind) {
  $parts = $Current.Split(".") | ForEach-Object { [int]$_ }
  if ($BumpKind -eq "major") {
    $parts[0] += 1
    $parts[1] = 0
    $parts[2] = 0
  } elseif ($BumpKind -eq "minor") {
    $parts[1] += 1
    $parts[2] = 0
  } else {
    $parts[2] += 1
  }
  return ($parts -join ".")
}

function Set-JsonVersion([string]$Path, [string]$NextVersion) {
  if (-not (Test-Path $Path)) {
    return
  }

  $resolvedPath = (Resolve-Path $Path).Path
  $jsonText = [System.IO.File]::ReadAllText($resolvedPath, [System.Text.UTF8Encoding]::new($false))
  $json = $jsonText | ConvertFrom-Json
  if ($json.PSObject.Properties.Name -notcontains "version") {
    $json | Add-Member -NotePropertyName "version" -NotePropertyValue $NextVersion
  } else {
    $json.version = $NextVersion
  }
  $updatedJson = $json | ConvertTo-Json -Depth 10
  [System.IO.File]::WriteAllText($resolvedPath, $updatedJson + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Replace-InFile([string]$Path, [string]$Pattern, [string]$Replacement) {
  if (-not (Test-Path $Path)) {
    return
  }

  $resolvedPath = (Resolve-Path $Path).Path
  $content = [System.IO.File]::ReadAllText($resolvedPath, [System.Text.UTF8Encoding]::new($false))
  $updated = [regex]::Replace($content, $Pattern, $Replacement)
  if ($updated -ne $content) {
    [System.IO.File]::WriteAllText($resolvedPath, $updated, [System.Text.UTF8Encoding]::new($false))
  }
}

$current = Get-CurrentVersion
$next = if ($Version) { $Version } else { Get-NextVersion $current $Bump }
$tag = "v$next"

Set-Content "VERSION" $next -Encoding ascii
Set-JsonVersion "package.json" $next
Set-JsonVersion "manifest.webmanifest" $next
Replace-InFile "service-worker.js" 'startline-mvp-v\d+\.\d+\.\d+' "startline-mvp-v$next"
Replace-InFile "index.html" '(<meta name="app-version" content=")[^"]+(">)' "`${1}$next`${2}"
Replace-InFile "index.html" '(<div class="status-pill" id="versionPill">v)[^<]+(</div>)' "`${1}$next`${2}"

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

Invoke-Git add .
$changes = & git status --porcelain
if ($LASTEXITCODE -ne 0) {
  throw "git status failed."
}
if (-not $changes) {
  Write-Host "No file changes to back up. Current version: $next"
} else {
  $commitMessage = if ($Message) { $Message } else { "chore: backup $tag" }
  Invoke-Git commit -m $commitMessage
}

$tagExists = $false
try {
  & git rev-parse -q --verify "refs/tags/$tag" *> $null
  if ($LASTEXITCODE -ne 0) {
    throw "tag not found"
  }
  $tagExists = $true
} catch {
  $tagExists = $false
}

if (-not $tagExists) {
  Invoke-Git tag -a $tag -m "Backup $tag"
}

$remote = $null
try {
  $remote = (& git remote get-url origin 2>$null).Trim()
  if ($LASTEXITCODE -ne 0) {
    throw "remote not found"
  }
} catch {
  $remote = $null
}

if ($NoPush) {
  Write-Host "Created local backup $tag. Push skipped because -NoPush was set."
} elseif ($remote) {
  Invoke-Git push -u origin main
  Invoke-Git push origin $tag
  Write-Host "Backed up $tag to GitHub: $remote"
} else {
  Write-Host "Created local backup $tag."
  Write-Host "GitHub remote is not set yet. After creating a GitHub repo, run:"
  Write-Host "  git remote add origin https://github.com/YOUR_NAME/startline-mvp.git"
  Write-Host "  git push -u origin main --tags"
}
