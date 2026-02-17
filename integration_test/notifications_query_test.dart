import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lanka_connect/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification query orders by createdAt desc', (tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _connectEmulators();

    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final email = 'notify_$suffix@example.com';
    const password = 'pass1234';

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;

    await firestore.collection('users').doc(uid).set({
      'role': 'seeker',
      'name': 'Notification Test',
      'district': 'Colombo',
      'city': 'Nugegoda',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await firestore.collection('notifications').add({
      'recipientId': uid,
      'senderId': uid,
      'title': 'One',
      'body': 'Old',
      'type': 'test',
      'isRead': false,
      'createdAt': Timestamp.fromDate(
        DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    });
    await firestore.collection('notifications').add({
      'recipientId': uid,
      'senderId': uid,
      'title': 'Two',
      'body': 'New',
      'type': 'test',
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });

    final query = await firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(2)
        .get();

    expect(query.docs.length, 2);
    expect(query.docs.first.data()['title'], 'Two');
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
