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
    & (Join-Path $scriptDir "publish-pages.ps1")
    if ($LASTEXITCODE -ne 0) {
      throw "Publishing GitHub Pages failed."
    }
  } else {
    Write-Host "Committed locally. GitHub remote is not set."
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
