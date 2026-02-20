import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/permissions/required_permissions_screen.dart';
import 'ui/mobile/mobile_theme.dart';
import 'ui/theme/app_theme_controller.dart';
import 'firebase_options.dart';
import 'utils/firebase_env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseEnv.configure();
  debugPrint(
    'Firebase boot: projectId=${DefaultFirebaseOptions.currentPlatform.projectId}',
  );
  debugPrint(
    'Firebase boot: useEmulators=${FirebaseEnv.useEmulators} backend=${FirebaseEnv.backendLabel()}',
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
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
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
