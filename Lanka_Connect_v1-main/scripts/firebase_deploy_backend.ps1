Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$preflightScript = Join-Path $scriptRoot "firebase_preflight.ps1"

& $preflightScript
if ($LASTEXITCODE -ne 0) {
  throw "Preflight failed."
}

firebase deploy --only firestore:rules,firestore:indexes,storage,functions
if ($LASTEXITCODE -ne 0) {
  throw "Firebase deploy failed."
}

Write-Host "Firebase backend deploy completed."
