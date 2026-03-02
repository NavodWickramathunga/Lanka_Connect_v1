// Web-compatible integration test driver.
//
// Usage:
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/<test_file>.dart \
//     -d chrome \
//     --dart-define=USE_FIREBASE_EMULATORS=true \
//     --dart-define=FIREBASE_EMULATOR_HOST=localhost
//
// This driver enables headless Chrome-based integration testing for the web
// platform using the `integration_test` package's web driver adapter.

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
