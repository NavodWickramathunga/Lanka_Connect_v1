import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/notification_service.dart';
import '../../utils/user_roles.dart';
import '../chat/chat_screen.dart';
import '../payments/payment_screen.dart';
import '../reviews/review_form_screen.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    String bookingId,
    String status,
    String seekerId,
  ) async {
    try {
      await FirestoreRefs.bookings().doc(bookingId).update({'status': status});
      await NotificationService.create(
        recipientId: seekerId,
        title: 'Booking status updated',
        body: 'Your booking is now "$status".',
        type: 'booking',
        data: {'bookingId': bookingId, 'status': status},
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
              return const Center(child: Text('No bookings yet.'));
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final status = data['status']?.toString() ?? 'pending';
                final serviceId = data['serviceId']?.toString() ?? 'Unknown';
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text('Service: $serviceId'),
                    subtitle: Text('Status: $status'),
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
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
