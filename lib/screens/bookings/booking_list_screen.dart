import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/mobile/mobile_components.dart';
import '../../ui/mobile/mobile_page_scaffold.dart';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../utils/display_name_utils.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/notification_service.dart';
import '../../utils/user_roles.dart';
import '../chat/chat_screen.dart';
import '../payments/payment_screen.dart';
import '../reviews/review_form_screen.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  String _shortId(String id, {int length = 8}) {
    final value = id.trim();
    if (value.isEmpty) return 'Unknown';
    final take = value.length < length ? value.length : length;
    return value.substring(0, take);
  }

  Future<void> _updateStatus(
    BuildContext context,
    String bookingId,
    String status,
    String seekerId,
    String providerId,
  ) async {
    try {
      await FirestoreRefs.bookings().doc(bookingId).update({'status': status});
      await NotificationService.createMany(
        recipientIds: [seekerId, providerId],
        title: 'Booking status updated',
        body: 'Booking ${bookingId.substring(0, bookingId.length > 6 ? 6 : bookingId.length)} is now "$status".',
        type: 'booking',
        data: {'bookingId': bookingId, 'status': status},
      );
      await NotificationService.notifyAdmins(
        title: 'Booking status changed',
        body: 'Booking status changed to "$status".',
        data: {
          'bookingId': bookingId,
          'status': status,
          'providerId': providerId,
          'seekerId': seekerId,
        },
      );
    } on FirebaseException catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'bookings_update_status',
        error: e,
        stackTrace: st,
        details: {'bookingId': bookingId, 'status': status},
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    } catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'bookings_update_status_unknown',
        error: e,
        stackTrace: st,
        details: {'bookingId': bookingId, 'status': status},
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
      return const Center(child: Text('Not signed in'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.users().doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final role = UserRoles.normalize(snapshot.data?.data()?['role']);

        Query<Map<String, dynamic>> query = FirestoreRefs.bookings();
        if (role == UserRoles.provider) {
          query = query.where('providerId', isEqualTo: user.uid);
        } else {
          query = query.where('seekerId', isEqualTo: user.uid);
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, bookingSnapshot) {
            if (bookingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (bookingSnapshot.hasError) {
              return Center(
                child: Text(
                  FirestoreErrorHandler.toUserMessage(bookingSnapshot.error!),
                ),
              );
            }

            final docs = bookingSnapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              if (!kIsWeb) {
                return MobilePageScaffold(
                  title: 'Bookings',
                  subtitle: 'Track the lifecycle of your bookings',
                  accentColor: RoleVisuals.forRole(role).accent,
                  body: const MobileEmptyState(
                    title: 'No bookings yet.',
                    icon: Icons.event_busy,
                  ),
                );
              }
              return const WebPageScaffold(
                title: 'Bookings',
                subtitle: 'Track the lifecycle of your current bookings.',
                useScaffold: false,
                child: Center(child: Text('No bookings yet.')),
              );
            }

            final list = ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final status = data['status']?.toString() ?? 'pending';
                final serviceId = data['serviceId']?.toString() ?? 'Unknown';
                final amount = (data['amount'] is num)
                    ? (data['amount'] as num).toDouble()
                    : null;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirestoreRefs.services().doc(serviceId).snapshots(),
                    builder: (context, serviceSnapshot) {
                      final serviceData = serviceSnapshot.data?.data() ?? {};
                      final serviceTitle =
                          (serviceData['title'] ?? '').toString().trim();
                      final category =
                          (serviceData['category'] ?? '').toString().trim();
                      final city = serviceData['city'];
                      final district = serviceData['district'];
                      final location = DisplayNameUtils.locationLabel(
                        city: city,
                        district: district,
                        fallback: (serviceData['location'] ?? 'Location not set')
                            .toString(),
                      );

                      final readableTitle = serviceTitle.isNotEmpty
                          ? serviceTitle
                          : 'Service ${_shortId(serviceId)}';

                      final subtitleParts = <String>[
                        if (category.isNotEmpty) category,
                        if (location.trim().isNotEmpty) location,
                        if (amount != null) 'LKR ${amount.toStringAsFixed(0)}',
                        'Status: $status',
                      ];

                      return ListTile(
                        title: Text(readableTitle),
                        subtitle: Text(subtitleParts.join(' | ')),
                        leading: MobileStatusChip(
                          label: status,
                          color: status == 'accepted'
                              ? MobileTokens.secondary
                              : status == 'completed'
                              ? MobileTokens.primary
                              : status == 'rejected'
                              ? Colors.red
                              : MobileTokens.accent,
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline),
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(chatId: doc.id),
                                ),
                              ),
                            ),
                            if (role == UserRoles.provider && status == 'pending')
                              TextButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  doc.id,
                                  'accepted',
                                  (data['seekerId'] ?? '').toString(),
                                  (data['providerId'] ?? '').toString(),
                                ),
                                child: const Text('Accept'),
                              ),
                            if (role == UserRoles.provider && status == 'pending')
                              TextButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  doc.id,
                                  'rejected',
                                  (data['seekerId'] ?? '').toString(),
                                  (data['providerId'] ?? '').toString(),
                                ),
                                child: const Text('Reject'),
                              ),
                            if (role == UserRoles.provider && status == 'accepted')
                              TextButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  doc.id,
                                  'completed',
                                  (data['seekerId'] ?? '').toString(),
                                  (data['providerId'] ?? '').toString(),
                                ),
                                child: const Text('Complete'),
                              ),
                            if (role == UserRoles.seeker && status == 'accepted')
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PaymentScreen(bookingId: doc.id),
                                  ),
                                ),
                                child: const Text('Pay'),
                              ),
                            if (role == UserRoles.seeker && status == 'completed')
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ReviewFormScreen(
                                      bookingId: doc.id,
                                      serviceId: (data['serviceId'] ?? '')
                                          .toString(),
                                      providerId: (data['providerId'] ?? '')
                                          .toString(),
                                    ),
                                  ),
                                ),
                                child: const Text('Review'),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );

            if (!kIsWeb) {
              return MobilePageScaffold(
                title: 'Bookings',
                subtitle: 'Track the lifecycle of your bookings',
                accentColor: RoleVisuals.forRole(role).accent,
                body: list,
              );
            }

            return WebPageScaffold(
              title: 'Bookings',
              subtitle: 'Track the lifecycle of your current bookings.',
              useScaffold: false,
              child: list,
            );
          },
        );
      },
    );
  }
}
