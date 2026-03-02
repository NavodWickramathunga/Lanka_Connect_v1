Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
  [string]$EmulatorHost = "localhost"
)

Write-Host "Running Flutter web (Chrome) against Firebase emulators..."
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=$EmulatorHost
