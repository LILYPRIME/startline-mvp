param(
  [int]$DebounceSeconds = 45,
  [string]$MessagePrefix = "auto: backup",
  [switch]$Once
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

function Get-StatusLines {
  $status = & git status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw "git status failed."
  }
  return @($status | Where-Object { $_ -and $_.Trim() })
}

function Push-Backup {
  $changes = Get-StatusLines
  if ($changes.Count -eq 0) {
    Write-Host "No changes to back up."
    return
  }

  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
  $commitMessage = "$MessagePrefix $timestamp"

  Write-Host "Backing up $($changes.Count) changed item(s)..."
  Invoke-Git add .
  Invoke-Git commit -m $commitMessage

  $remote = $null
  try {
    $remote = (& git remote get-url origin 2>$null).Trim()
    if ($LASTEXITCODE -ne 0) {
      throw "remote not found"
    }
  } catch {
    $remote = $null
  }

  if ($remote) {
    Invoke-Git push origin main
    Write-Host "Pushed to GitHub: $remote"
    Publish-PagesBranch $remote
  } else {
    Write-Host "Committed locally. GitHub remote is not set."
  }
}

function Publish-PagesBranch([string]$RemoteUrl) {
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
      Invoke-Git checkout -B gh-pages
      Invoke-Git config user.name "StartLine Auto Backup"
      Invoke-Git config user.email "startline-auto-backup@users.noreply.github.com"
      Invoke-Git add .
      Invoke-Git commit -m ("deploy pages " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
      Invoke-Git remote add origin $RemoteUrl
      Invoke-Git push origin gh-pages --force
      Write-Host "Published static site to gh-pages."
    } finally {
      Pop-Location
    }
  } finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

if ($Once) {
  Push-Backup
  exit 0
}

Write-Host "StartLine auto GitHub backup is running."
Write-Host "Watching: $root"
Write-Host "Debounce: $DebounceSeconds seconds"
Write-Host "Stop: Ctrl + C"
Write-Host ""

$ignoredDirs = @(".git", "node_modules")
$state = [pscustomobject]@{
  LastChange = $null
  Pending = $false
}

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $root
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]"FileName, DirectoryName, LastWrite, Size"

$action = {
  $path = $Event.SourceEventArgs.FullPath
  foreach ($ignored in $Event.MessageData.IgnoredDirs) {
    if ($path -like "*\$ignored\*") {
      return
    }
  }

  $Event.MessageData.State.LastChange = Get-Date
  $Event.MessageData.State.Pending = $true
}

$messageData = [pscustomobject]@{
  IgnoredDirs = $ignoredDirs
  State = $state
}

$events = @()
$events += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action -MessageData $messageData
$events += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action -MessageData $messageData
$events += Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action $action -MessageData $messageData
$events += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action -MessageData $messageData

try {
  while ($true) {
    Start-Sleep -Seconds 2
    if (-not $state.Pending -or -not $state.LastChange) {
      continue
    }

    $elapsed = ((Get-Date) - $state.LastChange).TotalSeconds
    if ($elapsed -lt $DebounceSeconds) {
      continue
    }

    $state.Pending = $false
    try {
      Push-Backup
    } catch {
      Write-Host "Auto backup failed: $($_.Exception.Message)"
      Write-Host "Will retry after the next file change."
    }
  }
} finally {
  foreach ($event in $events) {
    Unregister-Event -SubscriptionId $event.Id -ErrorAction SilentlyContinue
  }
  $watcher.Dispose()
}
