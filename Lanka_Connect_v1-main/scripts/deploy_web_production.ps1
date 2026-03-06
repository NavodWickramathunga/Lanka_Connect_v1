<#
.SYNOPSIS
  Build the Flutter web app against production Firebase and deploy to Firebase Hosting.

.DESCRIPTION
  1. Builds Flutter web with APP_ENV=production (targets new-lanka-connect-app).
  2. Deploys the built output (build/web) to Firebase Hosting on the production project.

  The production Firebase config is already embedded in:
    lib/firebase_options_production.dart
  and is selected at runtime when APP_ENV=production (the default for web builds).

  For a staging web build instead use:
    flutter build web --dart-define=APP_ENV=staging

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts/deploy_web_production.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ProjectId = 'new-lanka-connect-app'

Write-Host ''
Write-Host '╔══════════════════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║   Lanka Connect – Web Deploy (Production)        ║' -ForegroundColor Cyan
Write-Host "║   Firebase project: $ProjectId  ║" -ForegroundColor Cyan
Write-Host '╚══════════════════════════════════════════════════╝' -ForegroundColor Cyan
Write-Host ''

# ── 1. Prerequisites ──────────────────────────────────────────────────────────
Write-Host '[1/3] Checking prerequisites…' -ForegroundColor Yellow

try {
    $flutterVersion = & flutter --version 2>&1 | Select-Object -First 1
    Write-Host "      Flutter: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host '      ERROR: Flutter not found. Install from https://flutter.dev' -ForegroundColor Red
    exit 1
}

try {
    $fbVersion = & firebase --version 2>&1
    Write-Host "      Firebase CLI: $fbVersion" -ForegroundColor Green
} catch {
    Write-Host '      ERROR: Firebase CLI not found. Run: npm install -g firebase-tools' -ForegroundColor Red
    exit 1
}

# ── 2. Flutter web build ──────────────────────────────────────────────────────
Write-Host ''
Write-Host '[2/3] Building Flutter web (production)…' -ForegroundColor Yellow
Write-Host '      --dart-define=APP_ENV=production' -ForegroundColor DarkGray

flutter build web --dart-define=APP_ENV=production --release

if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '      ERROR: Flutter web build failed.' -ForegroundColor Red
    exit 1
}
Write-Host '      Build complete → build/web' -ForegroundColor Green

# ── 3. Deploy to Firebase Hosting ────────────────────────────────────────────
Write-Host ''
Write-Host '[3/3] Deploying to Firebase Hosting…' -ForegroundColor Yellow
Write-Host "      Project: $ProjectId" -ForegroundColor DarkGray

firebase deploy --project $ProjectId --only hosting

if ($LASTEXITCODE -eq 0) {
    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════════╗' -ForegroundColor Green
    Write-Host '║   ✅  Web deployment successful!                 ║' -ForegroundColor Green
    Write-Host '╚══════════════════════════════════════════════════╝' -ForegroundColor Green
    Write-Host ''
    Write-Host "  Live URL: https://$ProjectId.web.app" -ForegroundColor Cyan
    Write-Host ''
} else {
    Write-Host ''
    Write-Host '╔══════════════════════════════════════════════════╗' -ForegroundColor Red
    Write-Host '║   ❌  Deployment failed                          ║' -ForegroundColor Red
    Write-Host '╚══════════════════════════════════════════════════╝' -ForegroundColor Red
    Write-Host ''
    Write-Host 'Common fixes:' -ForegroundColor Yellow
    Write-Host '  1. Not logged in         → firebase login'
    Write-Host '  2. Wrong active project  → firebase use new-lanka-connect-app'
    Write-Host '  3. Hosting not enabled   → Enable it at https://console.firebase.google.com'
    exit 1
}
