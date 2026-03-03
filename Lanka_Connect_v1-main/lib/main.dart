import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/permissions/required_permissions_screen.dart';
import 'screens/splash/startup_splash_screen.dart';
import 'ui/mobile/mobile_theme.dart';
import 'ui/theme/app_theme_controller.dart';
import 'firebase_options.dart';
import 'utils/firebase_env.dart';
import 'utils/fcm_service.dart';
import 'utils/app_logger.dart';

class AppNavigationContract {
  const AppNavigationContract._();

  static const String authLoginPath = '/auth';
  static const String authSignupPath = '/auth/signup';
}

/// Top-level background message handler for FCM.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('FCM background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Maps with latest renderer on Android for proper tile loading
  if (!kIsWeb) {
    final mapsImplementation = GoogleMapsFlutterPlatform.instance;
    if (mapsImplementation is GoogleMapsFlutterAndroid) {
      mapsImplementation.useAndroidViewSurface = true;
      await GoogleMapsFlutterAndroid().initializeWithRenderer(
        AndroidMapRenderer.latest,
      );
    }
  }

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
          home: const StartupFlowGate(),
        );
      },
    );
  }
}

class StartupFlowGate extends StatefulWidget {
  const StartupFlowGate({super.key});

  @override
  State<StartupFlowGate> createState() => _StartupFlowGateState();
}

class _StartupFlowGateState extends State<StartupFlowGate> {
  bool _showSplash = true;

  void _finishSplash() {
    if (!mounted) return;
    setState(() {
      _showSplash = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return StartupSplashScreen(onFinished: _finishSplash);
    }
    return const RequiredPermissionsScreen(child: AuthGate());
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
