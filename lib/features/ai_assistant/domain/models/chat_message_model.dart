// lib/data/models/chat_message_model.dart
import 'dart:convert';

enum ChatRole { user, model, error }

class ChatMessage {
  final String text;
  final ChatRole role;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.role, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();

  // Konversi dari Map/JSON menjadi objek ChatMessage
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    text: json['text'],
    role: ChatRole.values[json['role']],
    timestamp: DateTime.parse(json['timestamp']),
  );

  // Konversi dari objek ChatMessage menjadi Map/JSON
  Map<String, dynamic> toJson() => {
    'text': text,
    'role': role.index,
    'timestamp': timestamp.toIso8601String(),
  };
}

// Fungsi helper untuk mengubah list ChatMessage menjadi string JSON
String encodeChatMessages(List<ChatMessage> messages) => json.encode(
  messages.map<Map<String, dynamic>>((msg) => msg.toJson()).toList(),
);

// Fungsi helper untuk mengubah string JSON kembali menjadi list ChatMessage
List<ChatMessage> decodeChatMessages(String encodedMessages) {
  if (encodedMessages.isEmpty) return [];
  try {
    final List<dynamic> decoded = json.decode(encodedMessages);
    return decoded
        .map<ChatMessage>((item) => ChatMessage.fromJson(item))
        .toList();
  } catch (e) {
    return [];
  }
}
