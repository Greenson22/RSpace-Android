// lib/presentation/providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/services/chat_service.dart';
import '../../core/services/storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  final SharedPreferencesService _prefsService = SharedPreferencesService();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;

  ChatProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _prefsService.loadChatHistory();
    if (history.isEmpty) {
      _addInitialMessage();
    } else {
      _messages = history;
    }
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    await _prefsService.saveChatHistory(_messages);
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

    _messages.add(ChatMessage(text: text.trim(), role: ChatRole.user));
    _isTyping = true;
    notifyListeners();
    await _saveHistory();

    final response = await _chatService.getResponse(text.trim());
    _messages.add(response);
    _isTyping = false;
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearChat() async {
    _messages.clear();
    await _saveHistory();
    notifyListeners();
  }

  Future<void> startNewChat() async {
    _messages.clear();
    _addInitialMessage();
    await _saveHistory();
    notifyListeners();
  }
}
