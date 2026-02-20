import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/mobile/mobile_components.dart';
import '../../ui/mobile/mobile_page_scaffold.dart';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/web/web_page_scaffold.dart';
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

  Widget _servicePage({
    required BuildContext context,
    required String title,
    required Widget body,
    Color accentColor = MobileTokens.primary,
  }) {
    if (kIsWeb) {
      return WebPageScaffold(
        title: title,
        subtitle: 'Detailed service information and actions.',
        useScaffold: true,
        child: body,
      );
    }
    return MobilePageScaffold(
      title: title,
      subtitle: 'Detailed service information and actions.',
      accentColor: accentColor,
      useScaffold: true,
      body: body,
    );
  }

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
      final bookingRef = await FirestoreRefs.bookings().add({
        'serviceId': serviceId,
        'providerId': providerId,
        'seekerId': user.uid,
        'amount': amount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.createMany(
        recipientIds: [providerId, user.uid],
        title: 'Booking request created',
        body: 'Booking request for "$serviceTitle" is pending provider action.',
        type: 'booking',
        data: {
          'bookingId': bookingRef.id,
          'serviceId': serviceId,
          'providerId': providerId,
          'seekerId': user.uid,
          'status': 'pending',
        },
      );
      await NotificationService.notifyAdmins(
        title: 'New booking request',
        body: 'A new booking request was created for "$serviceTitle".',
        data: {
          'bookingId': bookingRef.id,
          'serviceId': serviceId,
          'providerId': providerId,
          'seekerId': user.uid,
          'status': 'pending',
        },
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
      final requestRef = await FirestoreRefs.requests().add({
        'serviceId': serviceId,
        'providerId': providerId,
        'seekerId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.createMany(
        recipientIds: [providerId, user.uid],
        title: 'Service request created',
        body: 'A request for "$serviceTitle" is now pending provider action.',
        type: 'request',
        data: {
          'requestId': requestRef.id,
          'serviceId': serviceId,
          'providerId': providerId,
          'seekerId': user.uid,
          'status': 'pending',
        },
      );
      await NotificationService.notifyAdmins(
        title: 'New service request',
        body: 'A new service request was created for "$serviceTitle".',
        data: {
          'requestId': requestRef.id,
          'serviceId': serviceId,
          'providerId': providerId,
          'seekerId': user.uid,
          'status': 'pending',
        },
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
      if (kIsWeb) {
        return const WebPageScaffold(
          title: 'Service',
          subtitle: 'Detailed service information and actions.',
          useScaffold: true,
          child: Center(child: Text('Not signed in')),
        );
      }
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.services().doc(serviceId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _servicePage(
            context: context,
            title: 'Service',
            body: Center(
              child: Text(FirestoreErrorHandler.toUserMessage(snapshot.error!)),
            ),
          );
        }
        if (!snapshot.hasData) {
          return _servicePage(
            context: context,
            title: 'Service',
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data();
        if (data == null) {
          return _servicePage(
            context: context,
            title: 'Service',
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

        return _servicePage(
          context: context,
          title: (data['title'] ?? 'Service').toString(),
          accentColor: MobileTokens.accent,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobileSectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          MobileStatusChip(
                            label: (data['status'] ?? 'pending').toString(),
                            color: (data['status'] ?? '') == 'approved'
                                ? MobileTokens.secondary
                                : MobileTokens.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data['category'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Location: $location'),
                      Text('Price: LKR ${data['price'] ?? ''}'),
                    ],
                  ),
                ),
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
                MobileSectionCard(
                  child: Text(data['description'] ?? ''),
                ),
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
