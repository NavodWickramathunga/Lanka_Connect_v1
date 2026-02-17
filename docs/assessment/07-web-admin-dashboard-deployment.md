# Web Admin Dashboard Deployment Evidence

Last updated: February 16, 2026.

## Objective

Satisfy the deliverable "Web-Based Admin Dashboard" with:

- Local web runtime validation (`flutter run -d chrome`)
- Preview Hosting deployment
- Live Hosting deployment

## 1. Local Runtime Validation (Chrome)

Command used:

```bash
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=localhost
```

Observed evidence:

- App launched in Chrome.
- Debug service started.
- Flutter run interactive command prompt appeared.
- No startup errors shown in run output.

Reference log file:

- `web_run_stdout.log`

## 2. Admin Web Shell Wiring Validation

Code path confirms admin-only web dashboard shell:

- `lib/screens/home/home_screen.dart`: `kIsWeb && role == UserRoles.admin`
- `lib/screens/admin/admin_web_dashboard_screen.dart`: tabbed dashboard (`Moderation`, `Users`, `Analytics`)

Role expectation:

- User document must contain `users/{uid}.role = "admin"` for this shell to render on web.

## 3. Production Build Validation

Command:

```bash
flutter build web --release
```

Result:

- Build completed successfully.
- `build/web` contains expected artifacts (`index.html`, `main.dart.js`, `assets`, service worker files).

## 4. Preview Channel Deployment

Command:

```bash
firebase hosting:channel:deploy admin-dashboard --expires 7d
```

Result:

- Preview channel created and deployed successfully.
- Preview URL:
  - `https://lankaconnect-app--admin-dashboard-4khmnqpw.web.app`
- Expiry:
  - `2026-02-23 22:46:43` (from CLI output)

## 5. Live Hosting Deployment

Command:

```bash
firebase deploy --only hosting
```

Result:

- Live channel release completed successfully.
- Live URL:
  - `https://lankaconnect-app.web.app`

## 6. URL Smoke Checks

Performed HTTP checks after deploy:

- `https://lankaconnect-app--admin-dashboard-4khmnqpw.web.app` -> HTTP `200`
- `https://lankaconnect-app.web.app` -> HTTP `200`

## 7. Assessment Evidence Checklist

- [x] Local Chrome run validated.
- [x] Web build generated.
- [x] Preview deploy completed with URL.
- [x] Live deploy completed with URL.
- [x] Hosted URLs respond with HTTP 200.
- [ ] Screenshot: admin dashboard in preview/live (capture manually in browser session).
- [ ] Screenshot: Moderation/Users/Analytics tabs visible (capture manually).
