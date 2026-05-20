// lib/features/progress/application/progress_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/progress_topic_model.dart';
import 'progress_service.dart';

class ProgressProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<ProgressTopic> _topics = [];
  List<ProgressTopic> get topics => _topics;

  // ==> BARU: State Manajemen Section
  List<String> _sections = ['Umum'];
  List<String> get sections => _sections;

  bool _showHidden = false;
  bool get showHidden => _showHidden;

  ProgressProvider() {
    fetchTopics();
  }

  Future<void> fetchTopics() async {
    _isLoading = true;
    notifyListeners();
    _topics = await _progressService.getAllTopics();

    // Ambil daftar bagian kustom dari lokal
    _sections = await _progressService.getTopicSections();

    // Validasi agar semua topik berada pada section yang terdaftar
    bool needsUpdate = false;
    for (var topic in _topics) {
      if (!_sections.contains(topic.section)) {
        topic.section = _sections.isNotEmpty ? _sections.first : 'Umum';
        await _progressService.saveTopic(topic);
        needsUpdate = true;
      }
    }
    if (needsUpdate) _topics = await _progressService.getAllTopics();

    _isLoading = false;
    notifyListeners();
  }

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    notifyListeners();
  }

  Future<void> toggleTopicVisibility(ProgressTopic topic) async {
    topic.isHidden = !topic.isHidden;
    await _progressService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> toggleVisibilityMultipleTopics(
    List<ProgressTopic> selectedTopics,
    bool makeHidden,
  ) async {
    _isLoading = true;
    notifyListeners();
    for (var topic in selectedTopics) {
      if (topic.isHidden != makeHidden) {
        topic.isHidden = makeHidden;
        await _progressService.saveTopic(topic);
      }
    }
    await fetchTopics();
  }

  Future<void> addTopic(String name, {String section = 'Umum'}) async {
    await _progressService.addTopic(name, section: section);
    await fetchTopics();
  }

  // ==> BARU: Reorder khusus untuk topik di dalam 1 section saja
  Future<void> reorderTopicsInSection(
    String section,
    int oldIndex,
    int newIndex,
  ) async {
    final sectionTopics = _topics.where((t) => t.section == section).toList();
    sectionTopics.sort((a, b) => a.position.compareTo(b.position));

    final item = sectionTopics.removeAt(oldIndex);
    sectionTopics.insert(newIndex, item);

    for (int i = 0; i < sectionTopics.length; i++) {
      sectionTopics[i].position = i;
      await _progressService.saveTopic(sectionTopics[i]);
    }
    await fetchTopics();
  }

  Future<void> editTopic(ProgressTopic oldTopic, String newName) async {
    await _progressService.renameTopic(oldTopic, newName);
    await fetchTopics();
  }

  Future<void> editTopicIcon(ProgressTopic topic, String newIcon) async {
    topic.icon = newIcon;
    await _progressService.saveTopic(topic);
    notifyListeners();
  }

  Future<void> deleteTopic(ProgressTopic topic) async {
    await _progressService.deleteTopic(topic);
    await fetchTopics();
  }

  Future<void> duplicateTopic(ProgressTopic topic) async {
    _isLoading = true;
    notifyListeners();

    final topicJson = topic.toJson();
    topicJson['topics'] = '${topic.topics} (Salinan)';
    final newTopic = ProgressTopic.fromJson(topicJson);

    await _progressService.saveTopic(newTopic);
    await fetchTopics();
  }

  Future<void> deleteMultipleTopics(List<ProgressTopic> selectedTopics) async {
    _isLoading = true;
    notifyListeners();
    for (var topic in selectedTopics) {
      await _progressService.deleteTopic(topic);
    }
    await fetchTopics();
  }

  // ==> BARU: Manajamen Section (Tambah, Edit, Hapus, Reorder)
  Future<void> addSection(String sectionName) async {
    if (!_sections.contains(sectionName) && sectionName.isNotEmpty) {
      _sections.add(sectionName);
      await _progressService.saveTopicSections(_sections);
      notifyListeners();
    }
  }

  Future<void> renameSection(String oldName, String newName) async {
    final index = _sections.indexOf(oldName);
    if (index != -1 && !_sections.contains(newName) && newName.isNotEmpty) {
      _sections[index] = newName;
      await _progressService.saveTopicSections(_sections);

      // Update semua topik yang menggunakan section ini
      for (var topic in _topics.where((t) => t.section == oldName)) {
        topic.section = newName;
        await _progressService.saveTopic(topic);
      }
      await fetchTopics();
    }
  }

  Future<void> deleteSection(String sectionName) async {
    _sections.remove(sectionName);
    if (_sections.isEmpty) {
      _sections.add('Umum');
    }
    await _progressService.saveTopicSections(_sections);

    // Pindahkan topik di section yg dihapus ke section pertama yang tersedia
    final fallbackSection = _sections.first;
    for (var topic in _topics.where((t) => t.section == sectionName)) {
      topic.section = fallbackSection;
      await _progressService.saveTopic(topic);
    }
    await fetchTopics();
  }

  Future<void> reorderSections(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _sections.removeAt(oldIndex);
    _sections.insert(newIndex, item);
    await _progressService.saveTopicSections(_sections);
    notifyListeners();
  }

  Future<void> moveMultipleTopicsToSection(
    List<ProgressTopic> selectedTopics,
    String newSection,
  ) async {
    _isLoading = true;
    notifyListeners();
    for (var topic in selectedTopics) {
      topic.section = newSection;
      await _progressService.saveTopic(topic);
    }
    await fetchTopics();
  }
}
