# Limitations and Future Work

## Current Limitations (Spark Plan)

1. No deployed Cloud Functions in demo baseline.
- Side effects are executed in-app via Firestore writes/transactions.
- This is valid for assessment demos but not ideal for trust boundaries in production.

2. Push notifications are in-app/document-based only.
- Notification records are written to Firestore.
- No FCM push delivery pipeline is included in Spark baseline.

3. Payments are demo-only.
- Payment records are simulated in Firestore (`gateway: demo`).
- No real payment gateway integration, reconciliation, or webhook handling.

4. Some integration execution is device-target specific.
- `integration_test` execution is verified on Android device targets.
- Web integration execution via `flutter test` is not available.

## Future Work (Blaze / Production Track)

1. Move sensitive side effects to backend Cloud Functions (Blaze).
- Service moderation notifications.
- Provider rating aggregate updates.
- Demo/ops seed jobs (as admin-only callable or scheduled tasks).

2. Add real push notifications.
- Integrate Firebase Cloud Messaging.
- Add token lifecycle management and topic/user targeting.

3. Introduce real payments.
- Integrate payment provider SDK and backend webhook verification.
- Add idempotency keys, refund flows, and settlement reporting.

4. Improve observability and operations.
- Structured logging and alerting for errors and fraud patterns.
- Dashboards for moderation SLAs and transaction success rates.

5. Strengthen QA automation.
- Expand emulator-backed integration matrix on CI.
- Add deterministic seed/teardown for repeatable end-to-end suites.
