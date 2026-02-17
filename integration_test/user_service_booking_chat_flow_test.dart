import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lanka_connect/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signup -> user doc -> service -> booking -> chat', (
    tester,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _connectEmulators();

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final providerEmail = 'provider_$suffix@example.com';
    final seekerEmail = 'seeker_$suffix@example.com';
    const password = 'pass1234';

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final providerCredential = await auth.createUserWithEmailAndPassword(
      email: providerEmail,
      password: password,
    );
    final providerId = providerCredential.user!.uid;
    await firestore.collection('users').doc(providerId).set({
      'role': 'provider',
      'name': 'Provider Test',
      'district': 'Colombo',
      'city': 'Nugegoda',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await auth.signOut();

    final seekerCredential = await auth.createUserWithEmailAndPassword(
      email: seekerEmail,
      password: password,
    );
    final seekerId = seekerCredential.user!.uid;
    await firestore.collection('users').doc(seekerId).set({
      'role': 'seeker',
      'name': 'Seeker Test',
      'district': 'Colombo',
      'city': 'Maharagama',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await auth.signOut();

    await auth.signInWithEmailAndPassword(
      email: providerEmail,
      password: password,
    );
    final serviceRef = await firestore.collection('services').add({
      'providerId': providerId,
      'title': 'Integration Test Service',
      'category': 'Testing',
      'price': 1000,
      'district': 'Colombo',
      'city': 'Nugegoda',
      'location': 'Nugegoda, Colombo',
      'lat': 6.8656 + Random().nextDouble() / 100,
      'lng': 79.8997 + Random().nextDouble() / 100,
      'description': 'Created by integration test',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await auth.signOut();

    await auth.signInWithEmailAndPassword(
      email: seekerEmail,
      password: password,
    );
    final bookingRef = await firestore.collection('bookings').add({
      'serviceId': serviceRef.id,
      'providerId': providerId,
      'seekerId': seekerId,
      'amount': 1000,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await auth.signOut();

    await auth.signInWithEmailAndPassword(
      email: providerEmail,
      password: password,
    );
    await firestore.collection('bookings').doc(bookingRef.id).update({
      'status': 'accepted',
    });
    await auth.signOut();

    await auth.signInWithEmailAndPassword(
      email: seekerEmail,
      password: password,
    );
    await firestore.collection('messages').add({
      'chatId': bookingRef.id,
      'senderId': seekerId,
      'text': 'Hello provider, booking confirmed.',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final messageQuery = await firestore
        .collection('messages')
        .where('chatId', isEqualTo: bookingRef.id)
        .orderBy('createdAt', descending: false)
        .limit(1)
        .get();

    expect(messageQuery.docs.isNotEmpty, true);
  });
}

Future<void> _connectEmulators() async {
  const useEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: true,
  );
  if (!useEmulators) return;

  final host = _host();
  await FirebaseAuth.instance.useAuthEmulator(host, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
}

String _host() {
  const hostOverride = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '',
  );
  if (hostOverride.trim().isNotEmpty) return hostOverride.trim();
  if (kIsWeb) return 'localhost';
  if (defaultTargetPlatform == TargetPlatform.android) return '10.0.2.2';
  return 'localhost';
}
