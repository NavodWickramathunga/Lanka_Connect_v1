# Firebase Configuration Templates

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

If you need to manually configure, copy these templates to their proper locations and replace the placeholder values:

```bash
# Copy templates (if they don't exist)
cp .firebase_templates/firebase_options.dart lib/
cp .firebase_templates/google-services.json android/app/
cp .firebase_templates/GoogleService-Info.plist ios/Runner/

# Then edit each file to add your actual Firebase configuration values
```
