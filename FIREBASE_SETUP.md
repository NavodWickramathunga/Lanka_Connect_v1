# Firebase Setup Guide

This file contains the exact setup and deployment steps for Lanka Connect.

## 1) Prerequisites

- Flutter SDK installed
- Node.js 22+ installed
- Firebase CLI installed (`npm i -g firebase-tools`)
- FlutterFire CLI installed (`dart pub global activate flutterfire_cli`)
- A Firebase project (`lankaconnect-app`)

## 2) Configure Firebase App Files

From project root:

```bash
firebase login
flutterfire configure --project=lankaconnect-app --platforms=android,ios
```

This generates/updates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Policy for this repository:
- Do not commit `lib/firebase_options.dart`.
- Do not commit `android/app/google-services.json`.
- Do not commit `ios/Runner/GoogleService-Info.plist`.

If any file above is missing, regenerate with:

```bash
flutterfire configure --project=lankaconnect-app --platforms=android,ios
```

Before run/build, validate your machine setup:

```bash
powershell -ExecutionPolicy Bypass -File scripts/firebase_preflight.ps1
```

## 3) Install Dependencies

```bash
flutter pub get
cd functions
npm install
cd ..
```

## 4) Deploy Firestore + Functions

```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

## 5) Run the App

```bash
flutter run
```

## 6) Seed Demo Data (for presentation)

- Sign in as an admin user.
- In Home screen app bar, click the dataset icon.
- The app calls Cloud Function `seedDemoData` and inserts demo records.

Created demo entities include:
- provider profile (`users/demo_provider`)
- 3 services (2 approved, 1 pending)
- 2 bookings for the current admin user (accepted + completed)
- 1 review
- 1 notification to confirm seed completed

## 7) Firestore Indexes

If you add new compound Firestore queries and see "index required":

1. Open the error link from Flutter/console log.
2. Add index to `firestore.indexes.json`.
3. Redeploy indexes:

```bash
firebase deploy --only firestore:indexes
```

## 8) Emulator (Optional)

```bash
firebase emulators:start
```

Configured ports:
- Auth: `9099`
- Firestore: `8080`
- Storage: `9199`
- Functions: `5001`
- Emulator UI: `4000`

## Security Note

Do not commit sensitive Firebase config files to public repos.
