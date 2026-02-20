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
    final providerNotificationRef = FirestoreRefs.notifications().doc();
    final adminNotificationRef = FirestoreRefs.notifications().doc();

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
      final title = (serviceData['title'] ?? 'Service').toString();

      tx.update(serviceRef, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (providerId.isNotEmpty && previousStatus != status) {
        tx.set(providerNotificationRef, {
          'recipientId': providerId,
          'senderId': adminId,
          'title': 'Service moderation update',
          'body': 'Your service "$title" is now "$status".',
          'type': 'service_moderation',
          'data': {'serviceId': serviceId, 'status': status},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      tx.set(adminNotificationRef, {
        'recipientId': adminId,
        'senderId': adminId,
        'title': 'Moderation completed',
        'body': 'Service "$title" was marked "$status".',
        'type': 'admin_event',
        'data': {'serviceId': serviceId, 'status': status},
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
