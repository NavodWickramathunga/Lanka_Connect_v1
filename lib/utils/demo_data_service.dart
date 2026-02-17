import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final reviewId = 'demo_review_$suffix';

    final batch = db.batch();
    final now = FieldValue.serverTimestamp();

    final providerRef = db.collection('users').doc(providerId);
    batch.set(providerRef, {
      'role': 'provider',
      'name': 'Demo Provider',
      'contact': '+94770000000',
      'district': 'Colombo',
      'city': 'Maharagama',
      'skills': ['Home Cleaning', 'Plumbing'],
      'bio': 'Demo profile for presentation and testing.',
      'updatedAt': now,
    }, SetOptions(merge: true));

    final serviceOneRef = db.collection('services').doc(approvedServiceOneId);
    batch.set(serviceOneRef, {
      'providerId': providerId,
      'title': 'Home Deep Cleaning',
      'category': 'Cleaning',
      'price': 3500,
      'district': 'Colombo',
      'city': 'Nugegoda',
      'location': 'Nugegoda, Colombo',
      'description': 'Apartment and house deep cleaning service.',
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final serviceTwoRef = db.collection('services').doc(approvedServiceTwoId);
    batch.set(serviceTwoRef, {
      'providerId': providerId,
      'title': 'Quick Plumbing Fix',
      'category': 'Plumbing',
      'price': 2500,
      'district': 'Gampaha',
      'city': 'Kadawatha',
      'location': 'Kadawatha, Gampaha',
      'description': 'Leak repairs and basic plumbing maintenance.',
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final pendingServiceRef = db.collection('services').doc(pendingServiceId);
    batch.set(pendingServiceRef, {
      'providerId': providerId,
      'title': 'Math Tutoring (O/L)',
      'category': 'Tutoring',
      'price': 2000,
      'district': 'Colombo',
      'city': 'Dehiwala',
      'location': 'Dehiwala, Colombo',
      'description': 'One-to-one O/L maths support sessions.',
      'status': 'pending',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final acceptedBookingRef = db.collection('bookings').doc(acceptedBookingId);
    batch.set(acceptedBookingRef, {
      'serviceId': approvedServiceOneId,
      'providerId': providerId,
      'seekerId': callerUid,
      'amount': 3500,
      'status': 'accepted',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final completedBookingRef = db
        .collection('bookings')
        .doc(completedBookingId);
    batch.set(completedBookingRef, {
      'serviceId': approvedServiceTwoId,
      'providerId': providerId,
      'seekerId': callerUid,
      'amount': 2500,
      'status': 'completed',
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final reviewRef = db.collection('reviews').doc(reviewId);
    batch.set(reviewRef, {
      'bookingId': completedBookingId,
      'serviceId': approvedServiceTwoId,
      'providerId': providerId,
      'reviewerId': callerUid,
      'rating': 5,
      'comment': 'Reliable and quick service. Great for demo data.',
      'createdAt': now,
    }, SetOptions(merge: true));

    final notificationRef = db.collection('notifications').doc();
    batch.set(notificationRef, {
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
      },
      'isRead': false,
      'createdAt': now,
    });

    await batch.commit();

    await serviceOneRef.update({'status': 'approved', 'updatedAt': now});
    await serviceTwoRef.update({'status': 'approved', 'updatedAt': now});

    return {
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
}
