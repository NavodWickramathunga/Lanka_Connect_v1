import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_refs.dart';

class NotificationService {
  static Future<void> create({
    required String recipientId,
    required String title,
    required String body,
    String type = 'general',
    Map<String, dynamic> data = const {},
  }) async {
    final senderId = FirebaseAuth.instance.currentUser?.uid;
    if (senderId == null || recipientId.isEmpty) return;

    await FirestoreRefs.notifications().add({
      'recipientId': recipientId,
      'senderId': senderId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
