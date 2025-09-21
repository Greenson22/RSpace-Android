// lib/features/perpusku/application/perpusku_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/perpusku_models.dart';
import '../infrastructure/perpusku_service.dart';

class PerpuskuProvider with ChangeNotifier {
  final PerpuskuService _service = PerpuskuService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PerpuskuTopic> _topics = [];
  List<PerpuskuTopic> get topics => _topics;

  List<PerpuskuSubject> _subjects = [];
  List<PerpuskuSubject> get subjects => _subjects;

  List<PerpuskuFile> _files = [];
  List<PerpuskuFile> get files => _files;

  Future<void> fetchTopics() async {
    _setLoading(true);
    _topics = await _service.getTopics();
    _setLoading(false);
  }

  Future<void> fetchSubjects(String topicPath) async {
    _setLoading(true);
    _subjects = await _service.getSubjects(topicPath);
    _setLoading(false);
  }

  Future<void> fetchFiles(String subjectPath) async {
    _setLoading(true);
    _files = await _service.getFiles(subjectPath);
    _setLoading(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
