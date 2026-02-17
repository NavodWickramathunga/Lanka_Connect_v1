import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class FirebaseEnv {
  static const bool useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const String emulatorHostOverride = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '',
  );

  static Future<void> configure() async {
    if (!useEmulators) return;

    final host = _emulatorHost();

    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }

  static String backendLabel() {
    if (!useEmulators) return 'PROD';
    return 'EMULATOR(${_emulatorHost()})';
  }

  static String _emulatorHost() {
    if (emulatorHostOverride.trim().isNotEmpty) {
      return emulatorHostOverride.trim();
    }
    if (kIsWeb) return 'localhost';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }
}
