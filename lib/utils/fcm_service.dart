import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_refs.dart';

/// Handles FCM token lifecycle and push notification setup.
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Request permission and save the FCM token to Firestore.
  /// Call this after the user signs in.
  static Future<void> initialize() async {
    try {
      // Request permission (iOS/macOS/web require explicit permission)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: User denied notification permission.');
        return;
      }

      debugPrint('FCM: Permission status = ${settings.authorizationStatus}');

      // Get and save the token
      await _saveToken();

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenValue(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from terminated state via notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e, st) {
      debugPrint('FCM initialization error: $e');
      debugPrint(st.toString());
    }
  }

  /// Save current FCM token to the user's Firestore document.
  static Future<void> _saveToken() async {
    try {
      final token = await _messaging.getToken(
        vapidKey: kIsWeb
            ? null // Set your VAPID key here for web push
            : null,
      );

      if (token != null) {
        await _saveTokenValue(token);
      }
    } catch (e) {
      debugPrint('FCM: Failed to get token: $e');
    }
  }

  /// Persist an FCM token in the user's Firestore doc and fcm_tokens subcollection.
  static Future<void> _saveTokenValue(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    debugPrint(
      'FCM: Saving token for ${user.uid} (${token.substring(0, 10)}...)',
    );

    try {
      // Store latest token on user doc for simple single-device lookup
      await FirestoreRefs.users().doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also store in subcollection for multi-device support
      await FirestoreRefs.users()
          .doc(user.uid)
          .collection('fcm_tokens')
          .doc(token.hashCode.toString())
          .set({
            'token': token,
            'platform': _currentPlatform(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('FCM: Failed to save token: $e');
    }
  }

  /// Remove the FCM token on sign-out.
  static Future<void> removeToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        // Remove from subcollection
        await FirestoreRefs.users()
            .doc(user.uid)
            .collection('fcm_tokens')
            .doc(token.hashCode.toString())
            .delete();

        // Clear from user doc
        await FirestoreRefs.users().doc(user.uid).set({
          'fcmToken': FieldValue.delete(),
          'fcmTokenUpdatedAt': FieldValue.delete(),
        }, SetOptions(merge: true));
      }

      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('FCM: Failed to remove token: $e');
    }
  }

  /// Handle messages received while the app is in the foreground.
  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground message: ${message.notification?.title}');
    // The foreground message will be handled by the in-app notification
    // system via Firestore listeners already in place.
    // This handler is available for future custom UI (e.g., local notifications).
  }

  /// Handle when a user taps a notification while app is in background/terminated.
  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('FCM message opened app: ${message.data}');
    // Navigation based on message data can be added here.
    // For now, the app opens to the home screen where users see notifications.
  }

  static String _currentPlatform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
    return 'unknown';
  }
}
