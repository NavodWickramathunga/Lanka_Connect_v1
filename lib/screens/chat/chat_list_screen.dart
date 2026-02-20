import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/mobile/mobile_components.dart';
import '../../ui/mobile/mobile_page_scaffold.dart';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/user_roles.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  static const int _bookingIdDisplayLength = 6;

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
                child: Text('Failed to load chats: ${bookingSnapshot.error}'),
              );
            }

            final docs = bookingSnapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              if (!kIsWeb) {
                return MobilePageScaffold(
                  title: 'Chats',
                  subtitle: 'Messages from your active bookings',
                  accentColor: RoleVisuals.forRole(role).accent,
                  body: const MobileEmptyState(
                    title: 'No chats yet.',
                    icon: Icons.chat_bubble_outline,
                  ),
                );
              }
              return const WebPageScaffold(
                title: 'Chats',
                subtitle: 'Open booking conversations with seekers and providers.',
                useScaffold: false,
                child: Center(child: Text('No chats yet.')),
              );
            }

            final list = ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final status = data['status']?.toString() ?? 'Unknown';
                final bookingId = doc.id.length > _bookingIdDisplayLength
                    ? doc.id.substring(0, _bookingIdDisplayLength)
                    : doc.id;
                return ListTile(
                  leading: MobileStatusChip(
                    label: status,
                    color: status == 'accepted'
                        ? MobileTokens.secondary
                        : status == 'completed'
                        ? MobileTokens.primary
                        : MobileTokens.accent,
                  ),
                  title: Text('Booking $bookingId'),
                  subtitle: Text('Status: $status'),
                  trailing: const Icon(Icons.chat_bubble_outline),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(chatId: doc.id),
                    ),
                  ),
                );
              },
            );

            if (!kIsWeb) {
              return MobilePageScaffold(
                title: 'Chats',
                subtitle: 'Messages from your active bookings',
                accentColor: RoleVisuals.forRole(role).accent,
                body: list,
              );
            }
            return WebPageScaffold(
              title: 'Chats',
              subtitle: 'Open booking conversations with seekers and providers.',
              useScaffold: false,
              child: list,
            );
          },
        );
      },
    );
  }
}
