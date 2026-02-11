# Lanka Connect

Full-stack Flutter + Firebase service marketplace demo.

## Quick Start

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Configure Firebase for this app:
```bash
firebase login
flutterfire configure --project=lankaconnect-app
```

3. Install Cloud Functions dependencies:
```bash
cd functions
npm install
cd ..
```

4. Deploy backend config and functions:
```bash
firebase deploy --only firestore:rules,firestore:indexes,functions
```

5. Run app:
```bash
flutter run
```

For full setup details, see `FIREBASE_SETUP.md`.

## Demo Readiness Flow

1. Sign in as an `admin` user.
2. On Home app bar, tap the dataset icon to run demo seeding.
3. Verify demo data:
- `Services` tab: approved and pending sample services
- `Bookings` tab: accepted and completed sample bookings
- `Notifications`: "Demo data ready" message

## Submission Features

- Cloud Functions:
- set new service status to `pending`
- notify provider when service is approved
- update provider `averageRating` and `reviewCount` when review is added
- callable demo data seeder (`seedDemoData`)
- Firestore composite indexes in `firestore.indexes.json`
- Improved loading/empty/error states in core screens
- Stronger form validation (password, price, lat/lng, review comment, chat text)

## Report Assets

Use `REPORT_SCREENSHOTS.md` as the screenshot checklist for your report.
