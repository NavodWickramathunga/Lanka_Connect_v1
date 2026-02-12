import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/geo_utils.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/notification_service.dart';
import '../../utils/user_roles.dart';
import '../../widgets/service_map_preview.dart';
import 'service_map_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  Future<void> _createBooking(
    BuildContext context,
    String serviceId,
    String providerId,
    double amount,
    String serviceTitle,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirestoreErrorHandler.showSignInRequired(context);
      return;
    }

    try {
      await FirestoreRefs.bookings().add({
        'serviceId': serviceId,
        'providerId': providerId,
        'seekerId': user.uid,
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.create(
        recipientId: providerId,
        title: 'New booking request',
        body: 'A seeker requested booking for "$serviceTitle".',
        type: 'booking',
        data: {'serviceId': serviceId, 'seekerId': user.uid},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Booking request sent.')));
    } on FirebaseException catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'bookings_add',
        error: e,
        stackTrace: st,
        details: {
          'uid': user.uid,
          'serviceId': serviceId,
          'providerId': providerId,
        },
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    } catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'bookings_add_unknown',
        error: e,
        stackTrace: st,
        details: {
          'uid': user.uid,
          'serviceId': serviceId,
          'providerId': providerId,
        },
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    }
  }

  Future<void> _createRequest(
    BuildContext context,
    String serviceId,
    String providerId,
    String serviceTitle,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirestoreErrorHandler.showSignInRequired(context);
      return;
    }

    try {
      await FirestoreRefs.requests().add({
        'serviceId': serviceId,
        'providerId': providerId,
        'seekerId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.create(
        recipientId: providerId,
        title: 'New service request',
        body: 'A seeker created a request for "$serviceTitle".',
        type: 'request',
        data: {'serviceId': serviceId, 'seekerId': user.uid},
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Service request created.')));
    } on FirebaseException catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'requests_add',
        error: e,
        stackTrace: st,
        details: {
          'uid': user.uid,
          'serviceId': serviceId,
          'providerId': providerId,
        },
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    } catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'requests_add_unknown',
        error: e,
        stackTrace: st,
        details: {
          'uid': user.uid,
          'serviceId': serviceId,
          'providerId': providerId,
        },
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.services().doc(serviceId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Service')),
            body: Center(
              child: Text(
                FirestoreErrorHandler.toUserMessage(snapshot.error!),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Service')),
            body: const Center(child: Text('Service not found.')),
          );
        }
        final providerId = (data['providerId'] ?? '').toString();
        final city = (data['city'] ?? '').toString().trim();
        final district = (data['district'] ?? '').toString().trim();
        final location = (city.isNotEmpty || district.isNotEmpty)
            ? '$city, $district'
            : (data['location'] ?? '').toString();
        final point = GeoUtils.extractPoint(data);

        return Scaffold(
          appBar: AppBar(title: Text(data['title'] ?? 'Service')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data['category'] ?? '',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text('Location: $location'),
                Text('Price: LKR ${data['price'] ?? ''}'),
                if (point != null) ...[
                  const SizedBox(height: 12),
                  ServiceMapPreview(
                    point: point,
                    title: (data['title'] ?? 'Service').toString(),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ServiceMapScreen(
                            items: [
                              ServiceMapItem(
                                serviceId: serviceId,
                                title: (data['title'] ?? 'Service').toString(),
                                locationLabel: location,
                                priceLabel: 'LKR ${data['price'] ?? ''}',
                                point: point,
                              ),
                            ],
                            initialCenter: point,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 12),
                Text(data['description'] ?? ''),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirestoreRefs.reviews()
                      .where('serviceId', isEqualTo: serviceId)
                      .snapshots(),
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox(
                        height: 24,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (reviewSnapshot.hasError) {
                      return const Text('Could not load reviews right now.');
                    }
                    final reviews = reviewSnapshot.data?.docs ?? [];
                    if (reviews.isEmpty) {
                      return const Text('No reviews yet.');
                    }
                    final avg =
                        reviews
                            .map((doc) => (doc.data()['rating'] ?? 0) as int)
                            .fold<int>(0, (sum, item) => sum + item) /
                        reviews.length;
                    return Text('Average rating: ${avg.toStringAsFixed(1)}');
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirestoreRefs.users().doc(user.uid).snapshots(),
                  builder: (context, roleSnapshot) {
                    final role = UserRoles.normalize(
                      roleSnapshot.data?.data()?['role'],
                    );

                    if (role == UserRoles.provider) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () => _createBooking(
                            context,
                            serviceId,
                            providerId,
                            (data['price'] is num)
                                ? (data['price'] as num).toDouble()
                                : 0.0,
                            (data['title'] ?? 'service').toString(),
                          ),
                          child: const Text('Book Service'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => _createRequest(
                            context,
                            serviceId,
                            providerId,
                            (data['title'] ?? 'service').toString(),
                          ),
                          child: const Text('Create Request'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
