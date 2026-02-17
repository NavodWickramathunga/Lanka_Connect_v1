import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreErrorHandler {
  static String toUserMessage(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'Authentication failed. Please try again.';
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'not-found':
          return 'Requested record was not found.';
        case 'permission-denied':
          return 'Permission denied. Please sign in and try again.';
        case 'unauthenticated':
          return 'Please sign in to continue.';
        case 'unavailable':
          return 'Service is temporarily unavailable. Check your connection.';
        case 'deadline-exceeded':
          return 'Request timed out. Please try again.';
        case 'failed-precondition':
          return 'A required Firestore index/config is missing.';
        default:
          return error.message ?? 'Request failed. Please try again.';
      }
    }

    return 'Something went wrong. Please try again.';
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void showSignInRequired(BuildContext context) {
    showError(context, 'Please sign in to continue.');
  }

  static void logWriteError({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
    Map<String, Object?> details = const {},
  }) {
    debugPrint('Write error [$operation]: $error | details: $details');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
