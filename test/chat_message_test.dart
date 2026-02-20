import 'package:flutter_test/flutter_test.dart';
import 'package:lanka_connect/models/chat_message.dart';

void main() {
  group('ChatMessage.fromMap', () {
    test('parses a complete map', () {
      final m = ChatMessage.fromMap('m1', {
        'chatId': 'c1',
        'senderId': 'u1',
        'text': 'Hello',
      });

      expect(m.id, 'm1');
      expect(m.chatId, 'c1');
      expect(m.senderId, 'u1');
      expect(m.text, 'Hello');
    });

    test('fills defaults for missing fields', () {
      final m = ChatMessage.fromMap('m2', {});

      expect(m.chatId, '');
      expect(m.senderId, '');
      expect(m.text, '');
    });
  });

  group('ChatMessage.toMap', () {
    test('round-trips data', () {
      final m = ChatMessage(id: 'm1', chatId: 'c1', senderId: 'u1', text: 'Hi');
      final map = m.toMap();
      expect(map['chatId'], 'c1');
      expect(map['senderId'], 'u1');
      expect(map['text'], 'Hi');
      expect(map.containsKey('id'), isFalse);
    });
  });
}
