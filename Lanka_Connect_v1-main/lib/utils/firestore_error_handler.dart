import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class FirestoreErrorHandler {
  static String toUserMessage(Object error) {
    if (error is FirebaseAuthException) {
      return error.message ?? 'Authentication failed. Please try again.';
    }

    if (error is FirebaseFunctionsException) {
      final details = error.details;
      final extra = details == null ? '' : ' ($details)';
      switch (error.code) {
        case 'not-found':
          return 'Cloud Function not found. Deploy functions and try again.';
        case 'permission-denied':
          return 'Only admin users can run demo seeding.';
        case 'unauthenticated':
          return 'Please sign in again and retry.';
        case 'deadline-exceeded':
          return 'Demo seeding timed out. Check connection and retry.';
        default:
          return (error.message ?? 'Function request failed.') + extra;
      }
    }

    if (error is FirebaseException) {
      switch (error.code) {
        case 'not-found':
          return 'Requested backend endpoint not found. Deploy Cloud Functions.';
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
