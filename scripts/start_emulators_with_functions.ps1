Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Starting Firebase emulators (auth, firestore, storage, functions, ui)..."
firebase emulators:start
