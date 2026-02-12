Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Running Flutter app against Firebase emulators..."
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
