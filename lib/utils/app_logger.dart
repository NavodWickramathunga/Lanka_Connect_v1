import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Centralized logging and crash reporting service.
///
/// On native platforms (Android/iOS): integrates with Firebase Crashlytics.
/// On web: logs to console (Crashlytics is not supported on web).
class AppLogger {
  static bool _initialized = false;

  /// Initialize Crashlytics and set up Flutter error handlers.
  /// Call once during app startup, after Firebase.initializeApp().
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      debugPrint(
        'AppLogger: Crashlytics not available on web, using console logging.',
      );
      return;
    }

    // Pass all uncaught Flutter framework errors to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      // Also log to debug console
      FlutterError.presentError(errorDetails);
    };

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Opt in to collection (can be toggled for debug builds)
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode,
    );

    debugPrint(
      'AppLogger: Crashlytics initialized (collection=${kReleaseMode}).',
    );
  }

  /// Set the current user ID for crash reports.
  static Future<void> setUserId(String userId) async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }

  /// Clear user ID (on sign-out).
  static Future<void> clearUserId() async {
    if (kIsWeb) return;
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  /// Log a non-fatal error with optional context.
  static void logError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, String>? context,
  }) {
    final msg = reason != null ? '[$reason] $error' : '$error';
    debugPrint('ERROR: $msg');
    if (stackTrace != null) debugPrint(stackTrace.toString());

    if (!kIsWeb) {
      if (context != null) {
        for (final entry in context.entries) {
          FirebaseCrashlytics.instance.setCustomKey(entry.key, entry.value);
        }
      }
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason ?? 'non-fatal',
      );
    }
  }

  /// Log a breadcrumb / informational message.
  static void log(String message) {
    debugPrint('LOG: $message');
    if (!kIsWeb) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  /// Log an operation with structured details (used by FirestoreErrorHandler).
  static void logOperation({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> details = const {},
  }) {
    final detailStr = details.entries
        .map((e) => '${e.key}=${e.value}')
        .join(', ');
    final msg = 'Write error [$operation]: $error | $detailStr';
    debugPrint(msg);

    if (!kIsWeb) {
      FirebaseCrashlytics.instance.setCustomKey('operation', operation);
      for (final entry in details.entries) {
        if (entry.value != null) {
          FirebaseCrashlytics.instance.setCustomKey(
            entry.key,
            entry.value.toString(),
          );
        }
      }
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: 'operation:$operation',
      );
    }
  }
}
