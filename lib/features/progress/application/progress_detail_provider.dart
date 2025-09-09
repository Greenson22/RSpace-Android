// lib/features/progress/application/progress_detail_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/progress_subject_model.dart';
import '../domain/models/progress_topic_model.dart';
import 'progress_service.dart';

class ProgressDetailProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  ProgressTopic topic;

  ProgressDetailProvider(this.topic);

  Future<void> addSubject(String name) async {
    final newSubject = ProgressSubject(
      namaMateri: name,
      progress: "belum",
      subMateri: [],
    );
    topic.subjects.add(newSubject);
    await save();
    notifyListeners();
  }

  Future<void> addSubMateri(ProgressSubject subject, String name) async {
    final newSubMateri = SubMateri(namaMateri: name, progress: "belum");
    subject.subMateri.add(newSubMateri);
    _updateParentSubjectProgress(subject);
    await save();
    notifyListeners();
  }

  Future<void> updateSubMateriProgress(
    ProgressSubject subject,
    SubMateri subMateri,
    String newProgress,
  ) async {
    subMateri.progress = newProgress;
    _updateParentSubjectProgress(subject);
    await save();
    notifyListeners();
  }

  // Fungsi baru untuk mengedit nama sub-materi
  Future<void> editSubMateri(SubMateri subMateri, String newName) async {
    subMateri.namaMateri = newName;
    await save();
    notifyListeners();
  }

  // Fungsi baru untuk menghapus sub-materi
  Future<void> deleteSubMateri(
    ProgressSubject subject,
    SubMateri subMateri,
  ) async {
    subject.subMateri.remove(subMateri);
    _updateParentSubjectProgress(
      subject,
    ); // Update progress parent setelah hapus
    await save();
    notifyListeners();
  }

  void _updateParentSubjectProgress(ProgressSubject subject) {
    if (subject.subMateri.isEmpty) {
      subject.progress = "belum";
      return;
    }

    bool allFinished = subject.subMateri.every(
      (sub) => sub.progress == 'selesai',
    );
    if (allFinished) {
      subject.progress = 'selesai';
      return;
    }

    bool anyInProgress = subject.subMateri.any(
      (sub) => sub.progress == 'sementara',
    );
    if (anyInProgress) {
      subject.progress = 'sementara';
      return;
    }

    bool anyFinished = subject.subMateri.any(
      (sub) => sub.progress == 'selesai',
    );
    if (anyFinished) {
      subject.progress = 'sementara';
      return;
    }

    subject.progress = 'belum';
  }

  void update() {
    notifyListeners();
  }

  Future<void> save() async {
    await _progressService.saveTopic(topic);
  }
}
