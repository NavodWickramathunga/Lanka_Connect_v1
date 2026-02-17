Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "Starting Firebase emulators (auth, firestore, storage, ui)..."
firebase emulators:start --only "auth,firestore,storage,ui"
