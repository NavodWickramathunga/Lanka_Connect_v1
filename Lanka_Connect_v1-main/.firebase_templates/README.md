# Firebase Configuration Templates

> WARNING: Reference templates only. Do not copy these files into production as real Firebase config.

This directory contains template files for Firebase configuration that can be used as a reference.

## Files Available

- `firebase_options.dart` - Template for lib/firebase_options.dart
- `google-services.json` - Template for android/app/google-services.json  
- `GoogleService-Info.plist` - Template for ios/Runner/GoogleService-Info.plist

## Setup Instructions

See [FIREBASE_SETUP.md](../FIREBASE_SETUP.md) for detailed setup instructions.

## Using FlutterFire CLI (Recommended)

Run the following command to automatically generate the actual configuration files:

```bash
flutterfire configure --project=lankaconnect-app
```

This will create the required files in their proper locations with your actual Firebase project configuration.

## Manual Setup

Manual copy is for local experimentation only. Production-ready setup must be generated with:

```bash
flutterfire configure --project=lankaconnect-app --platforms=android,ios
```
