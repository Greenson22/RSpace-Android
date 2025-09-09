// lib/features/progress/application/progress_detail_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/progress_subject_model.dart';
import '../domain/models/progress_topic_model.dart';
import 'progress_service.dart';

class ProgressDetailProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  ProgressTopic topic;

  ProgressDetailProvider(this.topic);

  // Fungsi baru untuk menambahkan subject
  Future<void> addSubject(String name) async {
    final newSubject = ProgressSubject(
      namaMateri: name,
      progress: "belum", // Default progress
      subMateri: [],
    );
    topic.subjects.add(newSubject);
    await save(); // Simpan perubahan ke file JSON
    notifyListeners(); // Beri tahu UI untuk update
  }

  void update() {
    notifyListeners();
  }

  Future<void> save() async {
    await _progressService.saveTopic(topic);
  }
}
