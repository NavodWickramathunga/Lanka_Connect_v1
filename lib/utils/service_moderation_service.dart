import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_refs.dart';

class ServiceModerationService {
  static Future<void> updateStatus({
    required String serviceId,
    required String status,
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Please sign in to moderate services.',
      );
    }

    final serviceRef = FirestoreRefs.services().doc(serviceId);
    final notificationRef = FirestoreRefs.notifications().doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final serviceSnap = await tx.get(serviceRef);
      if (!serviceSnap.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'not-found',
          message: 'Service not found.',
        );
      }

      final serviceData = serviceSnap.data() ?? {};
      final providerId = (serviceData['providerId'] ?? '').toString();
      final previousStatus = (serviceData['status'] ?? '').toString();

      tx.update(serviceRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (status == 'approved' &&
          previousStatus != 'approved' &&
          providerId.isNotEmpty) {
        tx.set(notificationRef, {
          'recipientId': providerId,
          'senderId': adminId,
          'title': 'Service approved',
          'body': 'Your service has been approved by admin.',
          'type': 'service_moderation',
          'data': {'serviceId': serviceId, 'status': 'approved'},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
