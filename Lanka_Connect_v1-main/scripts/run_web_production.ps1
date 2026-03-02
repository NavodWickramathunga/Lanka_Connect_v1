Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Running Flutter web (Chrome) against production Firebase..."
flutter run -d chrome
