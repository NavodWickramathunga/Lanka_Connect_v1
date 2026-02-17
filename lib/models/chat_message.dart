class ChatMessage {
  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String text;

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      chatId: (data['chatId'] ?? '').toString(),
      senderId: (data['senderId'] ?? '').toString(),
      text: (data['text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
    };
  }
}
