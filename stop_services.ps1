$ErrorActionPreference = 'SilentlyContinue'

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateDir = Join-Path $rootDir '.run'

Write-Host 'Stopping services...'

# Try to stop any running MathLearning.Api processes (by process name or command line)
Write-Host '[INFO] Checking for MathLearning.Api processes to stop...'
try {
  $apiByName = Get-Process -Name 'MathLearning.Api' -ErrorAction SilentlyContinue
  if ($apiByName) {
    foreach ($p in $apiByName) {
      try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; Write-Host "[OK] Stopped MathLearning.Api (PID $($p.Id))." } catch { Write-Host "[WARN] Failed to stop MathLearning.Api (PID $($p.Id))." }
    }
  }

  # Also check processes whose command line contains the project name (covers 'dotnet' host)
  $apiByCmd = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -and ($_.CommandLine -match 'MathLearning.Api') }
  if ($apiByCmd) {
    foreach ($proc in $apiByCmd) {
      try { Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue; Write-Host "[OK] Stopped process (PID $($proc.ProcessId)) matching command line." } catch { Write-Host "[WARN] Failed to stop process (PID $($proc.ProcessId))." }
    }
  }
} catch {
  Write-Host '[WARN] Error while attempting to stop MathLearning.Api processes.'
}


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
