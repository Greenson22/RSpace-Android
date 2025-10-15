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

  NoteTopicProvider() {
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _noteService.getTopics();
    _isLoading = false;
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
