import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/service_moderation_service.dart';

class AdminServicesScreen extends StatelessWidget {
  const AdminServicesScreen({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    String serviceId,
    String status,
  ) async {
    try {
      await ServiceModerationService.updateStatus(
        serviceId: serviceId,
        status: status,
      );
    } on FirebaseException catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'services_update_status',
        error: e,
        stackTrace: st,
        details: {'serviceId': serviceId, 'status': status},
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    } catch (e, st) {
      FirestoreErrorHandler.logWriteError(
        operation: 'services_update_status_unknown',
        error: e,
        stackTrace: st,
        details: {'serviceId': serviceId, 'status': status},
      );
      FirestoreErrorHandler.showError(
        context,
        FirestoreErrorHandler.toUserMessage(e),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirestoreRefs.services()
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          if (!kIsWeb) return const Center(child: Text('No pending services.'));
          return const WebPageScaffold(
            title: 'Moderation',
            subtitle: 'Review and moderate pending service postings.',
            useScaffold: false,
            child: Center(child: Text('No pending services.')),
          );
        }

        final list = ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                title: Text(data['title'] ?? 'Service'),
                subtitle: Text(data['category'] ?? ''),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _updateStatus(context, doc.id, 'approved'),
                      child: const Text('Approve'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _updateStatus(context, doc.id, 'rejected'),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (!kIsWeb) return list;

        return WebPageScaffold(
          title: 'Moderation',
          subtitle: 'Review and moderate pending service postings.',
          useScaffold: false,
          child: list,
        );
      },
    );
  }
}
