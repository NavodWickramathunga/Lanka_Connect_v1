import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class DemoDataService {
  static Future<Map<String, dynamic>> seed() async {
    final callerUid = FirebaseAuth.instance.currentUser?.uid;
    if (callerUid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Sign in before seeding demo data.',
      );
    }

    final db = FirebaseFirestore.instance;
    final callerRef = db.collection('users').doc(callerUid);
    final callerSnap = await callerRef.get();
    final role = (callerSnap.data()?['role'] ?? '').toString().toLowerCase();
    if (role != 'admin') {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Only admin can seed demo data.',
      );
    }

    final providerId = 'demo_provider';
    const approvedServiceOneId = 'demo_service_cleaning';
    const approvedServiceTwoId = 'demo_service_plumbing';
    const pendingServiceId = 'demo_service_tutoring';
    final suffix = callerUid.substring(0, 6);
    final acceptedBookingId = 'demo_booking_accepted_$suffix';
    final completedBookingId = 'demo_booking_completed_$suffix';
    final result = <String, dynamic>{
      'ok': false,
      'created': 0,
      'updated': 0,
      'skipped': 0,
    };

    final providerRef = db.collection('users').doc(providerId);
    final serviceOneRef = db.collection('services').doc(approvedServiceOneId);
    final serviceTwoRef = db.collection('services').doc(approvedServiceTwoId);
    final pendingServiceRef = db.collection('services').doc(pendingServiceId);
    final acceptedBookingRef = db.collection('bookings').doc(acceptedBookingId);
    final completedBookingRef = db.collection('bookings').doc(completedBookingId);

    try {
      await providerRef.set({
        'role': 'provider',
        'name': 'Demo Provider',
        'email': 'demo.provider@lankaconnect.app',
        'contact': '+94770000000',
        'district': 'Colombo',
        'city': 'Maharagama',
        'skills': ['Home Cleaning', 'Plumbing'],
        'bio': 'Demo profile for presentation and testing.',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      result['updated'] = (result['updated'] as int) + 1;
    } catch (e, st) {
      _logPhaseError('seed_demo_provider', e, st);
      throw _seedPhaseException('seed_demo_provider', e);
    }

    try {
      await _seedService(
        ref: serviceOneRef,
        payload: {
          'providerId': providerId,
          'title': 'Home Deep Cleaning',
          'category': 'Cleaning',
          'price': 3500,
          'district': 'Colombo',
          'city': 'Nugegoda',
          'location': 'Nugegoda, Colombo',
          'description': 'Apartment and house deep cleaning service.',
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        desiredStatus: 'approved',
        result: result,
      );
      await _seedService(
        ref: serviceTwoRef,
        payload: {
          'providerId': providerId,
          'title': 'Quick Plumbing Fix',
          'category': 'Plumbing',
          'price': 2500,
          'district': 'Gampaha',
          'city': 'Kadawatha',
          'location': 'Kadawatha, Gampaha',
          'description': 'Leak repairs and basic plumbing maintenance.',
          'status': 'approved',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        desiredStatus: 'approved',
        result: result,
      );
      await _seedService(
        ref: pendingServiceRef,
        payload: {
          'providerId': providerId,
          'title': 'Math Tutoring (O/L)',
          'category': 'Tutoring',
          'price': 2000,
          'district': 'Colombo',
          'city': 'Dehiwala',
          'location': 'Dehiwala, Colombo',
          'description': 'One-to-one O/L maths support sessions.',
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        desiredStatus: 'pending',
        result: result,
      );
    } catch (e, st) {
      _logPhaseError('seed_demo_services', e, st);
      throw _seedPhaseException('seed_demo_services', e);
    }

    try {
      await _ensureBooking(
        ref: acceptedBookingRef,
        createPayload: {
          'serviceId': approvedServiceOneId,
          'providerId': providerId,
          'seekerId': callerUid,
          'amount': 3500,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        desiredStatus: 'accepted',
        result: result,
      );

      await _ensureBooking(
        ref: completedBookingRef,
        createPayload: {
          'serviceId': approvedServiceTwoId,
          'providerId': providerId,
          'seekerId': callerUid,
          'amount': 2500,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        desiredStatus: 'completed',
        result: result,
      );
    } catch (e, st) {
      _logPhaseError('seed_demo_bookings', e, st);
      throw _seedPhaseException('seed_demo_bookings', e);
    }

    late final String reviewId;
    try {
      reviewId = await _createReviewAndAggregate(
        db: db,
        providerRef: providerRef,
        completedBookingId: completedBookingId,
        serviceId: approvedServiceTwoId,
        providerId: providerId,
        reviewerId: callerUid,
      );
      result['created'] = (result['created'] as int) + 1;
    } catch (e, st) {
      _logPhaseError('seed_demo_review', e, st);
      throw _seedPhaseException('seed_demo_review', e);
    }

    try {
      final notificationRef = db.collection('notifications').doc();
      await notificationRef.set({
        'recipientId': callerUid,
        'senderId': callerUid,
        'title': 'Demo data ready',
        'body': 'Seed completed successfully. Refresh tabs to view sample data.',
        'type': 'system',
        'data': {
          'services': [
            approvedServiceOneId,
            approvedServiceTwoId,
            pendingServiceId,
          ],
          'bookings': [acceptedBookingId, completedBookingId],
          'summary': {
            'created': result['created'],
            'updated': result['updated'],
            'skipped': result['skipped'],
          },
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      result['created'] = (result['created'] as int) + 1;
    } catch (e, st) {
      _logPhaseError('seed_demo_notification', e, st);
      throw _seedPhaseException('seed_demo_notification', e);
    }

    return {
      ...result,
      'ok': true,
      'providerId': providerId,
      'services': [
        approvedServiceOneId,
        approvedServiceTwoId,
        pendingServiceId,
      ],
      'bookings': [acceptedBookingId, completedBookingId],
      'reviewId': reviewId,
    };
  }

  static Future<void> _seedService({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> payload,
    required String desiredStatus,
    required Map<String, dynamic> result,
  }) async {
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(payload);
      result['created'] = (result['created'] as int) + 1;
      return;
    }

    final currentStatus = (snap.data()?['status'] ?? '').toString();
    if (currentStatus == desiredStatus) {
      result['skipped'] = (result['skipped'] as int) + 1;
      return;
    }

    await ref.update({
      'status': desiredStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    result['updated'] = (result['updated'] as int) + 1;
  }

  static Future<void> _ensureBooking({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> createPayload,
    required String desiredStatus,
    required Map<String, dynamic> result,
  }) async {
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set(createPayload);
      result['created'] = (result['created'] as int) + 1;
    }

    final status = (snap.data()?['status'] ?? createPayload['status'] ?? 'pending')
        .toString();

    if (desiredStatus == 'accepted') {
      if (status == 'accepted' || status == 'completed') {
        result['skipped'] = (result['skipped'] as int) + 1;
        return;
      }
      await ref.update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      result['updated'] = (result['updated'] as int) + 1;
      return;
    }

    if (status == 'completed') {
      result['skipped'] = (result['skipped'] as int) + 1;
      return;
    }

    if (status == 'pending') {
      await ref.update({
        'status': 'accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      result['updated'] = (result['updated'] as int) + 1;
    }

    await ref.update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    result['updated'] = (result['updated'] as int) + 1;
  }

  static Future<String> _createReviewAndAggregate({
    required FirebaseFirestore db,
    required DocumentReference<Map<String, dynamic>> providerRef,
    required String completedBookingId,
    required String serviceId,
    required String providerId,
    required String reviewerId,
  }) async {
    final reviewRef = db.collection('reviews').doc();
    await db.runTransaction((tx) async {
      final providerSnap = await tx.get(providerRef);
      final providerData = providerSnap.data() ?? {};
      final safeAverage = _asDouble(providerData['averageRating']) ?? 0.0;
      final safeCount = _asInt(providerData['reviewCount']) ?? 0;
      final newCount = safeCount + 1;
      final newAverage = ((safeAverage * safeCount) + 5) / newCount;

      tx.set(reviewRef, {
        'bookingId': completedBookingId,
        'serviceId': serviceId,
        'providerId': providerId,
        'reviewerId': reviewerId,
        'rating': 5,
        'comment': 'Reliable and quick service. Great for demo data.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.set(providerRef, {
        'averageRating': double.parse(newAverage.toStringAsFixed(2)),
        'reviewCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    return reviewRef.id;
  }

  static void _logPhaseError(String phase, Object error, StackTrace stackTrace) {
    debugPrint('Seed error [$phase]: $error');
    debugPrint(stackTrace.toString());
  }

  static FirebaseException _seedPhaseException(String phase, Object error) {
    if (error is FirebaseException) {
      return FirebaseException(
        plugin: error.plugin,
        code: error.code,
        message: 'Seed failed at $phase: ${error.message ?? error.code}',
      );
    }
    return FirebaseException(
      plugin: 'cloud_firestore',
      code: 'seed-failed',
      message: 'Seed failed at $phase: $error',
    );
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
