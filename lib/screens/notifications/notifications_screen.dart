import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(BuildContext context, String id) async {
    try {
      await FirestoreRefs.notifications().doc(id).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (!context.mounted) return;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreRefs.notifications()
            .where('recipientId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(FirestoreErrorHandler.toUserMessage(snapshot.error!)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['title'] ?? 'Notification').toString();
              final body = (data['body'] ?? '').toString();
              final isRead = (data['isRead'] ?? false) == true;

              return ListTile(
                leading: Icon(
                  isRead ? Icons.notifications_none : Icons.notifications,
                ),
                title: Text(title),
                subtitle: Text(body),
                trailing: isRead
                    ? null
                    : TextButton(
                        onPressed: () => _markRead(context, doc.id),
                        child: const Text('Mark read'),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
