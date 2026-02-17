import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/notification_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _saving = false;
  String _shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;

  Future<void> _simulatePayment({
    required String status,
    required Map<String, dynamic> booking,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirestoreErrorHandler.showSignInRequired(context);
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final serviceId = (booking['serviceId'] ?? '').toString();
      final providerId = (booking['providerId'] ?? '').toString();
      final seekerId = (booking['seekerId'] ?? '').toString();
      final amount = (booking['amount'] is num)
          ? (booking['amount'] as num).toDouble()
          : 0.0;

      await FirestoreRefs.payments().add({
        'bookingId': widget.bookingId,
        'serviceId': serviceId,
        'providerId': providerId,
        'seekerId': seekerId,
        'payerId': user.uid,
        'amount': amount,
        'currency': 'LKR',
        'status': status,
        'gateway': 'demo',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await NotificationService.create(
        recipientId: providerId,
        title: status == 'success'
            ? 'Payment received'
            : 'Payment attempt failed',
        body: 'Booking ${_shortId(widget.bookingId)} payment status: $status.',
        type: 'payment',
        data: {'bookingId': widget.bookingId, 'status': status},
      );

      await NotificationService.create(
        recipientId: seekerId,
        title: status == 'success' ? 'Payment success' : 'Payment failed',
        body: 'Demo payment completed with status: $status.',
        type: 'payment',
        data: {'bookingId': widget.bookingId, 'status': status},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demo payment status saved: $status')),
        );
      }
    } on FirebaseException catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'payments_add',
        error: e,
        stackTrace: st,
        details: {'bookingId': widget.bookingId, 'status': status},
      );
      if (mounted) {
        FirestoreErrorHandler.showError(
          context,
          FirestoreErrorHandler.toUserMessage(e),
        );
      }
    } catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'payments_add_unknown',
        error: e,
        stackTrace: st,
        details: {'bookingId': widget.bookingId, 'status': status},
      );
      if (mounted) {
        FirestoreErrorHandler.showError(
          context,
          FirestoreErrorHandler.toUserMessage(e),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Payment (Demo)')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirestoreRefs.bookings().doc(widget.bookingId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(FirestoreErrorHandler.toUserMessage(snapshot.error!)),
            );
          }

          final booking = snapshot.data?.data();
          if (booking == null) {
            return const Center(child: Text('Booking not found.'));
          }

          final status = (booking['status'] ?? '').toString();
          final isSeeker = (booking['seekerId'] ?? '').toString() == user.uid;
          if (!isSeeker) {
            return const Center(child: Text('Only seeker can make payment.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Booking: ${_shortId(widget.bookingId)}'),
                        const SizedBox(height: 6),
                        Text('Current booking status: $status'),
                        const SizedBox(height: 6),
                        Text('Amount (demo): LKR ${booking['amount'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saving || status != 'accepted'
                      ? null
                      : () => _simulatePayment(
                          status: 'success',
                          booking: booking,
                        ),
                  child: Text(
                    _saving ? 'Processing...' : 'Simulate Success Payment',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _saving || status != 'accepted'
                      ? null
                      : () => _simulatePayment(
                          status: 'failed',
                          booking: booking,
                        ),
                  child: const Text('Simulate Failed Payment'),
                ),
                if (status != 'accepted') ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Payment is enabled only when booking status is accepted.',
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
