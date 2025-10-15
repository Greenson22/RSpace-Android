// lib/features/notes/application/note_topic_provider.dart

import 'package:flutter/material.dart';
import 'package:my_aplication/features/notes/domain/models/note_topic_model.dart';
import 'package:my_aplication/features/notes/infrastructure/note_service.dart';

class NoteTopicProvider with ChangeNotifier {
  final NoteService _noteService = NoteService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<NoteTopic> _topics = [];
  List<NoteTopic> get topics => _topics;

  // ==> STATE BARU UNTUK MODE URUTKAN <==
  bool _isReorderModeEnabled = false;
  bool get isReorderModeEnabled => _isReorderModeEnabled;

  NoteTopicProvider() {
    fetchTopics();
  }

  // ==> FUNGSI BARU UNTUK TOGGLE MODE <==
  void toggleReorderMode() {
    _isReorderModeEnabled = !_isReorderModeEnabled;
    notifyListeners();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _noteService.getTopics();
    _isLoading = false;
    notifyListeners();
  }

  // ==> FUNGSI BARU UNTUK MENGURUTKAN <==
  Future<void> reorderTopics(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _topics.removeAt(oldIndex);
    _topics.insert(newIndex, item);

    await _noteService.saveTopicsOrder(_topics);
    notifyListeners();
  }

  Future<void> addTopic(String name) async {
    await _noteService.createTopic(name);
    await fetchTopics();
  }

  Future<void> renameTopic(String oldName, String newName) async {
    await _noteService.renameTopic(oldName, newName);
    await fetchTopics();
  }

  Future<void> updateTopicIcon(NoteTopic topic, String newIcon) async {
    topic.icon = newIcon;
    await _noteService.saveTopic(topic);
    await fetchTopics();
  }

  Future<void> deleteTopic(String name) async {
    await _noteService.deleteTopic(name);
    await fetchTopics();
  }
}
