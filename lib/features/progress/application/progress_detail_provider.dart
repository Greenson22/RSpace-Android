// lib/features/progress/application/progress_detail_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service_flutter_gemini.dart';
import '../domain/models/color_palette_model.dart';
import '../domain/models/progress_subject_model.dart';
import '../domain/models/progress_topic_model.dart';
import 'palette_service.dart';
import 'progress_service.dart';

enum SubMateriInsertPosition { top, beforeFinished, bottom }

class ProgressDetailProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  final PaletteService _paletteService = PaletteService();
  final GeminiServiceFlutterGemini _geminiService =
      GeminiServiceFlutterGemini();
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

  Future<ColorPalette> generateAndSavePalette({required String theme}) async {
    try {
      final paletteName = '$theme (AI)';
      final newPalette = await _geminiService.suggestColorPalette(
        theme: theme,
        paletteName: paletteName,
      );
      await saveNewPalette(newPalette);
      return newPalette;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomPalette(ColorPalette palette) async {
    _customPalettes.removeWhere((p) => p.name == palette.name);
    await _paletteService.savePalettes(_customPalettes);
    notifyListeners();
  }

  Future<void> reorderSubjects(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = topic.subjects.removeAt(oldIndex);
    topic.subjects.insert(newIndex, item);
    await save();
    notifyListeners();
  }

  Future<void> reorderSubMateri(
    ProgressSubject subject,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = subject.subMateri.removeAt(oldIndex);
    subject.subMateri.insert(newIndex, item);
    await save();
    notifyListeners();
  }

  Future<void> moveSubMateriToBottom(
    ProgressSubject subject,
    SubMateri subMateri,
  ) async {
    subject.subMateri.remove(subMateri);
    subject.subMateri.add(subMateri);
    await save();
    notifyListeners();
  }

  // ==> FUNGSI BARU DITAMBAHKAN DI SINI <==
  Future<void> finishAndMoveSubMateriToBottom(
    ProgressSubject subject,
    SubMateri subMateri,
  ) async {
    // 1. Update status dan tanggal
    subMateri.progress = 'selesai';
    subMateri.finishedDate = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());

    // 2. Pindahkan ke bawah
    subject.subMateri.remove(subMateri);
    subject.subMateri.add(subMateri);

    // 3. Update progres parent dan simpan
    _updateParentSubjectProgress(subject);
    await save();
    notifyListeners();
  }

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

  Future<void> addSubMateri(
    ProgressSubject subject,
    String name, {
    SubMateriInsertPosition position = SubMateriInsertPosition.bottom,
  }) async {
    final newSubMateri = SubMateri(namaMateri: name, progress: "belum");

    switch (position) {
      case SubMateriInsertPosition.top:
        subject.subMateri.insert(0, newSubMateri);
        break;
      case SubMateriInsertPosition.beforeFinished:
        final firstFinishedIndex = subject.subMateri.indexWhere(
          (s) => s.progress == 'selesai',
        );
        if (firstFinishedIndex != -1) {
          subject.subMateri.insert(firstFinishedIndex, newSubMateri);
        } else {
          subject.subMateri.add(newSubMateri);
        }
        break;
      case SubMateriInsertPosition.bottom:
        subject.subMateri.add(newSubMateri);
        break;
    }

    _updateParentSubjectProgress(subject);
    await save();
    notifyListeners();
  }

  Future<void> addSubMateriInRange(
    ProgressSubject subject,
    String prefix,
    int start,
    int end, {
    SubMateriInsertPosition position = SubMateriInsertPosition.bottom,
  }) async {
    final List<SubMateri> newSubMateriList = [];
    for (int i = start; i <= end; i++) {
      newSubMateriList.add(
        SubMateri(namaMateri: '$prefix$i', progress: 'belum'),
      );
    }

    switch (position) {
      case SubMateriInsertPosition.top:
        subject.subMateri.insertAll(0, newSubMateriList);
        break;
      case SubMateriInsertPosition.beforeFinished:
        final firstFinishedIndex = subject.subMateri.indexWhere(
          (s) => s.progress == 'selesai',
        );
        if (firstFinishedIndex != -1) {
          subject.subMateri.insertAll(firstFinishedIndex, newSubMateriList);
        } else {
          subject.subMateri.addAll(newSubMateriList);
        }
        break;
      case SubMateriInsertPosition.bottom:
        subject.subMateri.addAll(newSubMateriList);
        break;
    }

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

    if (newProgress == 'selesai') {
      subMateri.finishedDate = DateFormat(
        'yyyy-MM-dd HH:mm',
      ).format(DateTime.now());
    } else {
      subMateri.finishedDate = null;
    }

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

  Future<void> deleteSelectedSubMateri(
    ProgressSubject subject,
    Set<SubMateri> subMateriToDelete,
  ) async {
    subject.subMateri.removeWhere((sub) => subMateriToDelete.contains(sub));
    _updateParentSubjectProgress(subject);
    await save();
    notifyListeners();
  }

  Future<void> moveSelectedSubMateri(
    ProgressSubject fromSubject,
    Set<SubMateri> subMateriToMove,
    ProgressSubject toSubject,
  ) async {
    fromSubject.subMateri.removeWhere((sub) => subMateriToMove.contains(sub));
    toSubject.subMateri.addAll(subMateriToMove);
    _updateParentSubjectProgress(fromSubject);
    _updateParentSubjectProgress(toSubject);
    await save();
    notifyListeners();
  }

  Future<void> moveSelectedSubMateriToAnotherTopic(
    ProgressSubject fromSubject,
    Set<SubMateri> subMateriToMove,
    ProgressTopic toTopic,
    ProgressSubject toSubject,
  ) async {
    fromSubject.subMateri.removeWhere((sub) => subMateriToMove.contains(sub));
    _updateParentSubjectProgress(fromSubject);
    await save();

    final destinationSubjectInTopic = toTopic.subjects.firstWhere(
      (s) => s.namaMateri == toSubject.namaMateri,
    );
    destinationSubjectInTopic.subMateri.addAll(subMateriToMove);
    _updateParentSubjectProgress(destinationSubjectInTopic);
    await _progressService.saveTopic(toTopic);

    notifyListeners();
  }

  Future<void> deleteAllSubMateri(ProgressSubject subject) async {
    subject.subMateri.clear();
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
