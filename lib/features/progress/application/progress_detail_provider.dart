// lib/features/progress/application/progress_detail_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_aplication/features/settings/application/services/gemini_service_flutter_gemini.dart';
import '../domain/models/color_palette_model.dart';
import '../domain/models/progress_subject_model.dart';
import '../domain/models/progress_topic_model.dart';
import 'palette_service.dart';
import 'progress_service.dart';
import '../domain/models/progress_template_model.dart';

enum SubMateriInsertPosition { top, beforeFinished, bottom }

class ProgressDetailProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();
  final PaletteService _paletteService = PaletteService();
  final GeminiServiceFlutterGemini _geminiService =
      GeminiServiceFlutterGemini();
  ProgressTopic topic;

  List<ColorPalette> _customPalettes = [];
  List<ColorPalette> get customPalettes => _customPalettes;

  // === TAMBAHKAN STATE TEMPLATE ===
  List<ProgressTemplate> _templates = [];
  List<ProgressTemplate> get templates => _templates;

  bool _showHidden = false;
  bool get showHidden => _showHidden;

  ProgressDetailProvider(this.topic) {
    _loadCustomPalettes();
    _loadTemplates(); // Panggil fungsi load template
  }

  // ==========================================
  // BAGIAN BARU: KELOLA SECTION (BAGIAN MATERI)
  // ==========================================

  List<ProgressSubject> getSubjectsBySection(String section) {
    return topic.subjects
        .where((s) => s.section == section && (!s.isHidden || showHidden))
        .toList();
  }

  List<ProgressSubject> get focusSubjects => getSubjectsBySection('focus');
  List<ProgressSubject> get queueSubjects => getSubjectsBySection('queue');
  List<ProgressSubject> get additionalSubjects =>
      getSubjectsBySection('additional');
  List<ProgressSubject> get archiveSubjects => getSubjectsBySection('archive');

  Future<void> moveSubjectToSection(
    ProgressSubject subject,
    String newSection,
  ) async {
    subject.section = newSection;
    await save();
    notifyListeners();
  }

  Future<void> moveMultipleSubjectsToSection(
    List<ProgressSubject> subjects,
    String newSection,
  ) async {
    bool changed = false;
    for (var subject in subjects) {
      if (subject.section != newSection) {
        subject.section = newSection;
        changed = true;
      }
    }
    if (changed) {
      await save();
      notifyListeners();
    }
  }

  Future<void> reorderSubjectInSection(
    String section,
    int oldIndex,
    int newIndex,
  ) async {
    final visibleSubjects = getSubjectsBySection(section);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final subjectToMove = visibleSubjects[oldIndex];
    // Masukkan ke urutan baru relatif terhadap list utama
    final mainOldIndex = topic.subjects.indexOf(subjectToMove);

    // Cari index tujuan di main list
    int mainNewIndex;
    if (visibleSubjects.isEmpty || newIndex >= visibleSubjects.length) {
      mainNewIndex = topic.subjects.length;
    } else {
      mainNewIndex = topic.subjects.indexOf(visibleSubjects[newIndex]);
    }

    final item = topic.subjects.removeAt(mainOldIndex);
    // Sesuaikan index jika bergeser
    if (mainOldIndex < mainNewIndex) {
      mainNewIndex -= 1;
    }
    topic.subjects.insert(mainNewIndex, item);

    await save();
    notifyListeners();
  }

  // ==========================================
  // FUNGSI LAMA
  // ==========================================

  void toggleShowHidden() {
    _showHidden = !_showHidden;
    notifyListeners();
  }

  Future<void> toggleSubjectVisibility(ProgressSubject subject) async {
    subject.isHidden = !subject.isHidden;
    await save();
    notifyListeners();
  }

  Future<void> toggleVisibilityMultipleSubjects(
    List<ProgressSubject> subjects,
    bool makeHidden,
  ) async {
    bool changed = false;
    for (var subject in subjects) {
      if (subject.isHidden != makeHidden) {
        subject.isHidden = makeHidden;
        changed = true;
      }
    }
    if (changed) {
      await save();
      notifyListeners();
    }
  }

  Future<void> deleteMultipleSubjects(List<ProgressSubject> subjects) async {
    topic.subjects.removeWhere((s) => subjects.contains(s));
    await save();
    notifyListeners();
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

  Future<void> finishAndMoveSubMateriToBottom(
    ProgressSubject subject,
    SubMateri subMateri,
  ) async {
    subMateri.progress = 'selesai';
    subMateri.finishedDate = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());

    subject.subMateri.remove(subMateri);
    subject.subMateri.add(subMateri);

    _updateParentSubjectProgress(subject);
    await save();
    notifyListeners();
  }

  Future<void> resetFinishedSubMateri(ProgressSubject subject) async {
    bool changed = false;
    for (var sub in subject.subMateri) {
      if (sub.progress == 'selesai') {
        sub.progress = 'belum';
        sub.finishedDate = null;
        changed = true;
      }
    }

    if (changed) {
      _updateParentSubjectProgress(subject);
      await save();
      notifyListeners();
    }
  }

  // [DI DALAM ProgressDetailProvider, GANTI addSubject DAN TAMBAHKAN FUNGSI BARU]

  Future<void> addSubject(
    String name, {
    String section = 'queue',
    String type = 'list',
  }) async {
    final newSubject = ProgressSubject(
      namaMateri: name,
      progress: "belum",
      subMateri: [],
      section: section,
      type: type,
      noteContent: type == 'note' ? '' : null,
    );
    topic.subjects.add(newSubject);
    await save();
    notifyListeners();
  }

  // --- FUNGSI UNTUK CATATAN ---
  Future<void> updateSubjectNoteContent(
    ProgressSubject subject,
    String content,
  ) async {
    subject.noteContent = content;
    await save();
    notifyListeners();
  }

  Future<void> updateSubjectProgressOnly(
    ProgressSubject subject,
    String progress,
  ) async {
    subject.progress = progress;
    await save();
    notifyListeners();
  }

  // --- FUNGSI PINDAH KE TOPIK LAIN ---
  Future<void> moveMultipleSubjectsToAnotherTopic(
    List<ProgressSubject> subjects,
    ProgressTopic destinationTopic,
  ) async {
    // Hapus materi dari topik saat ini
    topic.subjects.removeWhere((s) => subjects.contains(s));
    await save();

    // Tambahkan materi ke topik tujuan
    destinationTopic.subjects.addAll(subjects);
    await _progressService.saveTopic(destinationTopic);

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

  // Tambahkan fungsi baru ini di bawah addSubMateriInRange
  Future<void> addSubMateriFromList(
    ProgressSubject subject,
    List<String> items, { // Mengubah parameter menjadi List<String>
    SubMateriInsertPosition position = SubMateriInsertPosition.bottom,
  }) async {
    if (items.isEmpty) return;

    final List<SubMateri> newSubMateriList = items
        .map((name) => SubMateri(namaMateri: name, progress: 'belum'))
        .toList();

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

  // ==========================================
  // BAGIAN TEMPLATE
  // ==========================================

  Future<void> _loadTemplates() async {
    _templates = await _progressService.getTemplates();
    notifyListeners();
  }

  Future<void> saveAsTemplate(
    ProgressSubject subject,
    String templateName,
  ) async {
    final newTemplate = ProgressTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: templateName,
      subMateri: subject.subMateri.map((e) => e.namaMateri).toList(),
    );
    _templates.add(newTemplate);
    await _progressService.saveTemplates(_templates);
    notifyListeners();
  }

  Future<void> deleteTemplate(ProgressTemplate template) async {
    _templates.removeWhere((t) => t.id == template.id);
    await _progressService.saveTemplates(_templates);
    notifyListeners();
  }

  Future<void> addSubjectFromTemplate(
    String name,
    ProgressTemplate template, {
    String section = 'queue',
  }) async {
    final subMateriList = template.subMateri
        .map((mName) => SubMateri(namaMateri: mName, progress: 'belum'))
        .toList();

    final newSubject = ProgressSubject(
      namaMateri: name,
      progress: "belum",
      subMateri: subMateriList,
      section: section,
    );

    topic.subjects.add(newSubject);
    _updateParentSubjectProgress(newSubject);
    await save();
    notifyListeners();
  }
}
