Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [Parameter(Mandatory = $true)]
  [string]$DeviceId,
  [string]$TestPath = "integration_test\notifications_query_test.dart",
  [string]$EmulatorHost = ""
)

$args = @(
  "test",
  $TestPath,
  "-d",
  $DeviceId,
  "--dart-define=USE_FIREBASE_EMULATORS=true"
)

if (-not [string]::IsNullOrWhiteSpace($EmulatorHost)) {
  $args += "--dart-define=FIREBASE_EMULATOR_HOST=$EmulatorHost"
}

Write-Host "Running integration test '$TestPath' on device '$DeviceId'..."
flutter @args
