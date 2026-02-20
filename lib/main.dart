import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/permissions/required_permissions_screen.dart';
import 'ui/mobile/mobile_theme.dart';
import 'ui/theme/app_theme_controller.dart';
import 'firebase_options.dart';
import 'utils/firebase_env.dart';
import 'utils/fcm_service.dart';
import 'utils/app_logger.dart';

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseEnv.configure();
  await AppLogger.initialize();
  debugPrint(
    'Firebase boot: projectId=${DefaultFirebaseOptions.currentPlatform.projectId}',
  );
  debugPrint(
    'Firebase boot: useEmulators=${FirebaseEnv.useEmulators} backend=${FirebaseEnv.backendLabel()}',
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Lanka Connect',
          theme: MobileTheme.build(),
          darkTheme: MobileTheme.buildDark(),
          themeMode: mode,
          home: const RequiredPermissionsScreen(child: AuthGate()),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // Initialize FCM after successful authentication
          FcmService.initialize();
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
