import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'helpers/firebase_emulator_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('notification query orders by createdAt desc', (tester) async {
    await initializeFirebaseForIntegrationTests();
    await connectToEmulators();

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
