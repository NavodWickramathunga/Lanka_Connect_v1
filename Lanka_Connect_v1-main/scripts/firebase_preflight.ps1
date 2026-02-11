Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-Command {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name
  )

  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command '$Name' was not found in PATH."
  }
}

function Assert-File {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path
  )

  if (-not (Test-Path -Path $Path -PathType Leaf)) {
    throw "Required file is missing: $Path"
  }
}

Write-Host "Running Firebase preflight checks..."

Assert-Command -Name "firebase"
Assert-Command -Name "flutter"
Assert-Command -Name "flutterfire"
Assert-Command -Name "npm"

$loginOutput = firebase login:list 2>&1
if ($LASTEXITCODE -ne 0) {
  throw "Failed to verify Firebase login status. Run 'firebase login'."
}

$loginText = ($loginOutput | Out-String).Trim()
if ($loginText -match "No authorized accounts") {
  throw "No authorized Firebase account detected. Run 'firebase login'."
}

Assert-File -Path "lib/firebase_options.dart"
Assert-File -Path "firestore.rules"
Assert-File -Path "firestore.indexes.json"
Assert-File -Path "storage.rules"
Assert-File -Path "functions/package.json"

Push-Location "functions"
try {
  npm ci
  if ($LASTEXITCODE -ne 0) {
    throw "npm ci failed in functions/"
  }

  npm run lint
  if ($LASTEXITCODE -ne 0) {
    throw "npm run lint failed in functions/"
  }

  npm run build
  if ($LASTEXITCODE -ne 0) {
    throw "npm run build failed in functions/"
  }
}
finally {
  Pop-Location
}

Write-Host "Firebase preflight checks passed."
