import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_refs.dart';

class ReviewService {
  static Future<void> submitReview({
    required String bookingId,
    required String serviceId,
    required String providerId,
    required int rating,
    required String comment,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Please sign in to submit a review.',
      );
    }

    final reviewRef = FirestoreRefs.reviews().doc();
    final providerRef = FirestoreRefs.users().doc(providerId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(reviewRef, {
        'bookingId': bookingId,
        'serviceId': serviceId,
        'providerId': providerId,
        'reviewerId': user.uid,
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final providerSnap = await tx.get(providerRef);
      final providerData = providerSnap.data() ?? {};

      final currentAverage = (providerData['averageRating'] as num?)
          ?.toDouble();
      final currentCount = (providerData['reviewCount'] as num?)?.toInt();

      final safeAverage = currentAverage != null && currentAverage.isFinite
          ? currentAverage
          : 0.0;
      final safeCount = currentCount != null && currentCount > 0
          ? currentCount
          : 0;

      final newCount = safeCount + 1;
      final newAverage = ((safeAverage * safeCount) + rating) / newCount;

      tx.set(providerRef, {
        'averageRating': double.parse(newAverage.toStringAsFixed(2)),
        'reviewCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
