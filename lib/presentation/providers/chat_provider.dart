// lib/presentation/providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  ChatProvider() {
    _addInitialMessage();
  }

  void _addInitialMessage() {
    _messages.add(
      ChatMessage(
        text:
            'Hai! Saya Flo, asisten AI Anda. Tanyakan apa saja tentang data di aplikasi ini, misalnya "Tugas apa yang belum selesai?"',
        role: ChatRole.model,
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Tambahkan pesan pengguna ke daftar
    _messages.add(ChatMessage(text: text.trim(), role: ChatRole.user));
    _isTyping = true;
    notifyListeners();

    // Dapatkan respons dari service
    final response = await _chatService.getResponse(text.trim());
    _messages.add(response);
    _isTyping = false;
    notifyListeners();
  }
}
