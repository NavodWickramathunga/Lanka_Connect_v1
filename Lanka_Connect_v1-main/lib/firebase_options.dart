// File generated from Lanka Connect Firebase project configuration.
// Re-generate with:
// flutterfire configure --project=lankaconnect-app --platforms=android,ios
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          "DefaultFirebaseOptions have not been configured for this platform. "
          "Run flutterfire configure --project=lankaconnect-app --platforms=android,ios.",
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyBcinz104MNv8RjdZQX32w5acmreKhJ5Qw",
    appId: "1:262402675622:android:4155e440124b4dec67b567",
    messagingSenderId: "262402675622",
    projectId: "lankaconnect-app",
    storageBucket: "lankaconnect-app.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDjDrm_kbvjmpZdvOO0U2wWN9AAWqFrfRU",
    appId: "1:262402675622:ios:58958d1ce12a6fb367b567",
    messagingSenderId: "262402675622",
    projectId: "lankaconnect-app",
    storageBucket: "lankaconnect-app.firebasestorage.app",
    iosBundleId: "com.example.lankaConnect",
  );
}
