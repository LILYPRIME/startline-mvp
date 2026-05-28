$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$python = Join-Path $env:USERPROFILE ".cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe"
if (-not (Test-Path $python)) {
  $python = "python"
}

$ip = Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object {
    $_.IPAddress -notlike "127.*" -and
    $_.IPAddress -notlike "169.254.*" -and
    $_.PrefixOrigin -ne "WellKnown"
  } |
  Select-Object -First 1 -ExpandProperty IPAddress

if (-not $ip) {
  $ip = "PCのIPアドレス"
}

Write-Host ""
Write-Host "StartLine MVPをスマホで開くURL:"
Write-Host "  http://$ip`:8765/"
Write-Host ""
Write-Host "PCとスマホを同じWi-Fiに接続して、スマホのブラウザで上のURLを開いてください。"
Write-Host "終了するときは、この画面で Ctrl + C を押します。"
Write-Host ""

Set-Location $root
& $python -m http.server 8765 --bind 0.0.0.0

