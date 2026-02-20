import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../ui/mobile/mobile_page_scaffold.dart';
import '../../ui/mobile/mobile_tokens.dart';
import '../../ui/web/web_page_scaffold.dart';
import '../../utils/firestore_error_handler.dart';
import '../../utils/firestore_refs.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  bool _sending = false;
  String get _chatId => widget.chatId.trim();

  String _chatErrorMessage(Object error) {
    if (error is FirebaseException && error.code == 'failed-precondition') {
      return 'Chat index/config is missing. Please deploy Firestore indexes and retry.';
    }
    return FirestoreErrorHandler.toUserMessage(error);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_chatId.isEmpty) {
      FirestoreErrorHandler.showError(context, 'Invalid chat session.');
      return;
    }

    final text = _messageController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message cannot be empty.')));
      return;
    }
    if (text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message is too long (max 500 chars).')),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await FirestoreRefs.messages().add({
        'chatId': _chatId,
        'senderId': user.uid,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    } on FirebaseException catch (e) {
      if (mounted) {
        FirestoreErrorHandler.showError(context, _chatErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        FirestoreErrorHandler.showError(context, _chatErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kIsWeb) {
        return const WebPageScaffold(
          title: 'Chat',
          subtitle: 'Send and receive booking messages in real time.',
          useScaffold: true,
          child: Center(child: Text('Not signed in')),
        );
      }
      return const MobilePageScaffold(
        title: 'Chat',
        subtitle: 'Send and receive booking messages in real time.',
        accentColor: MobileTokens.accent,
        useScaffold: true,
        body: Center(child: Text('Not signed in')),
      );
    }
    if (_chatId.isEmpty) {
      if (kIsWeb) {
        return const WebPageScaffold(
          title: 'Chat',
          subtitle: 'Send and receive booking messages in real time.',
          useScaffold: true,
          child: Center(
            child: Text('Invalid chat reference. Open chat again from bookings.'),
          ),
        );
      }
      return const MobilePageScaffold(
        title: 'Chat',
        subtitle: 'Send and receive booking messages in real time.',
        accentColor: MobileTokens.accent,
        useScaffold: true,
        body: Center(
          child: Text('Invalid chat reference. Open chat again from bookings.'),
        ),
      );
    }

    final body = Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirestoreRefs.messages()
                  .where('chatId', isEqualTo: _chatId)
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_chatErrorMessage(snapshot.error!)),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMine = data['senderId'] == user.uid;
                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMine
                              ? const Color(0xFFDDEBFF)
                              : const Color(0xFFF2F6FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(data['text'] ?? ''),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                      ),
                      onSubmitted: (_) => _sending ? null : _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
    );

    if (kIsWeb) {
      return WebPageScaffold(
        title: 'Chat',
        subtitle: 'Send and receive booking messages in real time.',
        useScaffold: true,
        child: body,
      );
    }

    return MobilePageScaffold(
      title: 'Chat',
      subtitle: 'Send and receive booking messages in real time.',
      accentColor: MobileTokens.accent,
      useScaffold: true,
      body: body,
    );
  }
}
