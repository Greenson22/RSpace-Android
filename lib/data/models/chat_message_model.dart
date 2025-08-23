// lib/data/models/chat_message_model.dart
enum ChatRole { user, model, error }

class ChatMessage {
  final String text;
  final ChatRole role;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.role, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}
