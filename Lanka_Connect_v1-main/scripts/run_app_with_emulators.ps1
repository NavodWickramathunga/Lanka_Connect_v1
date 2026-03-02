Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [string]$EmulatorHost = ""
)

$args = @(
  "run",
  "--dart-define=USE_FIREBASE_EMULATORS=true"
)

if (-not [string]::IsNullOrWhiteSpace($EmulatorHost)) {
  $args += "--dart-define=FIREBASE_EMULATOR_HOST=$EmulatorHost"
}

Write-Host "Running Flutter app against Firebase emulators..."
flutter @args
