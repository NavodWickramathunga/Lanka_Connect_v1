# Test Plan and Results

Last updated: February 16, 2026.

## 1. Test Strategy

Test layers:

- Unit tests: pure logic and validators.
- Widget tests: UI rendering and auth-screen state transitions.
- Integration tests: Firebase emulator-backed end-to-end and rules behavior.
- UAT checklist: manual acceptance flow for assessment demo.

## 2. Planned Coverage Matrix

| Area | Unit | Widget | Integration | UAT |
|---|---|---|---|---|
| Validators and role helpers | Yes | No | Indirect | Yes |
| Auth entry UX | No | Yes | Indirect | Yes |
| Service create pending-only guard | Indirect | No | Yes | Yes |
| Admin approval + notification | No | No | Planned/Partial | Yes |
| Review aggregate materialization | No | No | Yes | Yes |
| Notification query/read behavior | No | No | Yes | Yes |
| Booking/chat baseline flow | No | No | Yes | Yes |

## 3. Automated Test Results

## 3.1 Unit + Widget (local)

Command:

```bash
flutter test test
```

Result:

- Passed: all tests in `test/`.
- Count observed: 19 passing tests.

## 3.2 Integration (Android device + emulators)

Device used:

- `SM A566E (wireless)` Android 16 (API 36)

Command (verified):

```bash
flutter test integration_test\notifications_query_test.dart -d "adb-R5CY90K7NYP-kEEBIk._adb-tls-connect._tcp" --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=192.168.8.105
```

Result:

- Passed: `notifications_query_test.dart`.

## 3.3 Additional integration suite present

The project contains additional integration tests, including:

- `integration_test/user_service_booking_chat_flow_test.dart`
- `integration_test/spark_rules_and_aggregate_test.dart`

These are intended to be executed against emulator-backed runtime on supported device targets.

## 3.4 Web runtime and hosting smoke results

Web runtime command:

```bash
flutter run -d chrome --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=FIREBASE_EMULATOR_HOST=localhost
```

Result:

- Chrome runtime launched and debug service connected.
- No startup errors reported during smoke window.

Hosting smoke:

- Preview URL and live URL both returned HTTP `200` after deployment.

## 4. UAT Checklist (Assessment Demo)

Mark each during final demo rehearsal.

- [ ] Sign up as seeker and provider users.
- [ ] Provider posts service and confirms status remains `pending`.
- [ ] Admin sees pending service in moderation view.
- [ ] Admin approves service and provider receives unread notification.
- [ ] Seeker sees approved service in list.
- [ ] Seeker creates booking for approved service.
- [ ] Provider accepts and completes booking.
- [ ] Seeker submits review; provider `reviewCount` and `averageRating` update.
- [ ] Chat messages visible between booking participants only.
- [ ] Notifications screen can mark own notifications as read.
- [ ] Admin dataset seed action creates sample entities and confirmation notification.

## 5. Exit Criteria for Submission

- Unit/widget test suite green.
- At least one integration flow demonstrated on emulator-backed runtime.
- UAT checklist completed with screenshot evidence in report.
