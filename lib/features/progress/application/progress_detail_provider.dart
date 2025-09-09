// lib/features/progress/application/progress_detail_provider.dart

import 'package:flutter/material.dart';
import '../domain/models/color_palette_model.dart';
import '../domain/models/progress_subject_model.dart';
import '../domain/models/progress_topic_model.dart';
import 'palette_service.dart';
import 'progress_service.dart';

class ProgressDetailProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  final PaletteService _paletteService = PaletteService();
  ProgressTopic topic;

  List<ColorPalette> _customPalettes = [];
  List<ColorPalette> get customPalettes => _customPalettes;

  ProgressDetailProvider(this.topic) {
    _loadCustomPalettes();
  }

  Future<void> _loadCustomPalettes() async {
    _customPalettes = await _paletteService.loadPalettes();
    notifyListeners();
  }

  Future<void> saveNewPalette(ColorPalette palette) async {
    _customPalettes.add(palette);
    await _paletteService.savePalettes(_customPalettes);
    notifyListeners();
  }

  // Fungsi baru untuk menghapus palet kustom
  Future<void> deleteCustomPalette(ColorPalette palette) async {
    _customPalettes.removeWhere((p) => p.name == palette.name);
    await _paletteService.savePalettes(_customPalettes);
    notifyListeners();
  }

  // ... (sisa kode tetap sama) ...
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

  Future<void> editSubject(ProgressSubject subject, String newName) async {
    subject.namaMateri = newName;
    await save();
    notifyListeners();
  }

  Future<void> deleteSubject(ProgressSubject subject) async {
    topic.subjects.remove(subject);
    await save();
    notifyListeners();
  }

  Future<void> updateSubjectColors(
    ProgressSubject subject, {
    Color? backgroundColor,
    Color? textColor,
    Color? progressBarColor,
  }) async {
    subject.backgroundColor = backgroundColor?.value;
    subject.textColor = textColor?.value;
    subject.progressBarColor = progressBarColor?.value;
    await save();
    notifyListeners();
  }

  Future<void> updateSubjectIcon(
    ProgressSubject subject,
    String newIcon,
  ) async {
    subject.icon = newIcon;
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

  Future<void> editSubMateri(SubMateri subMateri, String newName) async {
    subMateri.namaMateri = newName;
    await save();
    notifyListeners();
  }

  Future<void> deleteSubMateri(
    ProgressSubject subject,
    SubMateri subMateri,
  ) async {
    subject.subMateri.remove(subMateri);
    _updateParentSubjectProgress(subject);
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
