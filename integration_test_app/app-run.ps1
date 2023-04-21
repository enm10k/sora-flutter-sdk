# Usage:
# pwsh -File .\app-run.ps1 -timeoutSeconds 120

param (
    [int]$timeoutSeconds
)

if (!$timeoutSeconds) {
    Write-Host "Please specify a timeout using the -timeoutSeconds parameter."
    exit
}

$scriptDir = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
Set-Location $scriptDir

$job = Start-Job -ScriptBlock {
    &flutter run -d windows --release --dart-define=TEST_MODE=app_run
}
Start-Sleep -Seconds $timeoutSeconds
$job | Stop-Job
$job | Receive-Job
$job | Remove-Job
