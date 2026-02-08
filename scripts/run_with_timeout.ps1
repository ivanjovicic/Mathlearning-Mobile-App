param(
    [Parameter(Mandatory = $true)]
    [Alias("cmd")]
    [string]$Command,
    [int]$TimeoutSeconds = 30,
    [string]$WorkingDirectory = (Get-Location).Path
)

$job = Start-Job -ScriptBlock {
    param($InnerCommand, $InnerWorkingDirectory)
    Set-Location $InnerWorkingDirectory
    powershell.exe -NoProfile -Command $InnerCommand
} -ArgumentList $Command, $WorkingDirectory

if (-not (Wait-Job -Job $job -Timeout $TimeoutSeconds)) {
    Stop-Job -Job $job -Force | Out-Null
    Remove-Job -Job $job -Force | Out-Null
    Write-Host "Command timed out after $TimeoutSeconds seconds."
    exit 124
}

$output = Receive-Job -Job $job -Keep
$hadError = $job.State -eq 'Failed'
$exitCode = 0

if ($output) {
    $output
}

if ($hadError) {
    $exitCode = 1
}

Remove-Job -Job $job -Force | Out-Null
exit $exitCode
