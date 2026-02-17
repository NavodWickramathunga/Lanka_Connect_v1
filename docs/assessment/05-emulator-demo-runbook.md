# How To Run Demo On Emulators

This runbook is for Spark/free demo execution (no deployed Cloud Functions required).

## Important Backend Mode Note

- Production Firebase and local emulators are separate backends.
- Accounts/roles created in emulators do not appear in production.
- For the same account to work on app + web hosting, use production mode:
  - `scripts/run_app_production.ps1`
  - `scripts/run_web_production.ps1`

## Prerequisites

- Flutter SDK installed and on PATH.
- Firebase CLI installed and authenticated (`firebase login`).
- Android Studio/ADB set up (for Android device testing).
- Project Firebase config files generated:
  - `lib/firebase_options.dart`
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`

## Step 1: Install dependencies

```bash
flutter pub get
```

## Step 2: Start Firebase emulators

```bash
powershell -ExecutionPolicy Bypass -File scripts/start_emulators.ps1
```

Expected ports:

- Auth: `9099`
- Firestore: `8080`
- Storage: `9199`
- Emulator UI: `4000`

If startup fails with "port taken", stop the process currently holding that port and retry.

## Step 3: Run app against emulators

Local desktop/web target:

```bash
powershell -ExecutionPolicy Bypass -File scripts/run_app_with_emulators.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_web_with_emulators.ps1
```

Physical Android over Wi-Fi:

```bash
powershell -ExecutionPolicy Bypass -File scripts/run_app_with_emulators.ps1 -EmulatorHost <YOUR_PC_LAN_IP>
```

Example:

```bash
powershell -ExecutionPolicy Bypass -File scripts/run_app_with_emulators.ps1 -EmulatorHost 192.168.8.105
powershell -ExecutionPolicy Bypass -File scripts/run_web_with_emulators.ps1 -EmulatorHost 192.168.8.105
```

## Step 4: Run integration test on Android device (optional but recommended)

```bash
powershell -ExecutionPolicy Bypass -File scripts/run_integration_with_emulators.ps1 -DeviceId "<FLUTTER_DEVICE_ID>" -EmulatorHost <YOUR_PC_LAN_IP>
```

Example:

```bash
powershell -ExecutionPolicy Bypass -File scripts/run_integration_with_emulators.ps1 -DeviceId "adb-R5CY90K7NYP-kEEBIk._adb-tls-connect._tcp" -EmulatorHost 192.168.8.105
```

## Step 5: Demo validation flow

1. Sign in as admin.
2. Run dataset seed action (app bar dataset icon).
3. Check pending/approved services, bookings, and notifications.
4. Verify moderation, booking, chat, and review aggregate behaviors.
