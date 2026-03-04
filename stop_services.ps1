$ErrorActionPreference = 'SilentlyContinue'

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateDir = Join-Path $rootDir '.run'

Write-Host 'Stopping services...'

$targets = @(
  @{ Name = 'Backend'; PidFile = (Join-Path $stateDir 'backend.pid') },
  @{ Name = 'Flutter'; PidFile = (Join-Path $stateDir 'flutter.pid') }
)

foreach ($target in $targets) {
  $name = $target.Name
  $pidFile = $target.PidFile

  if (-not (Test-Path $pidFile)) {
    Write-Host "[INFO] $name pid file not found or empty."
    continue
  }

  $raw = (Get-Content -LiteralPath $pidFile | Select-Object -First 1).Trim()
  if (-not $raw) {
    Write-Host "[INFO] $name pid file not found or empty."
    Remove-Item -LiteralPath $pidFile -Force
    continue
  }

  [int]$targetPid = 0
  if (-not [int]::TryParse($raw, [ref]$targetPid)) {
    Write-Host "[WARN] $name pid is invalid: $raw"
    Remove-Item -LiteralPath $pidFile -Force
    continue
  }

  $proc = Get-Process -Id $targetPid
  if ($null -eq $proc) {
    Write-Host "[INFO] $name already stopped (PID $targetPid)."
  }
  else {
    Stop-Process -Id $targetPid -Force
    Write-Host "[OK] $name stopped (PID $targetPid)."
  }

  Remove-Item -LiteralPath $pidFile -Force
}

Write-Host ''
Write-Host '[DONE] Stop routine finished.'
